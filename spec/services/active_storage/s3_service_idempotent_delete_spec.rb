# frozen_string_literal: true

require "test_helper"

class ActiveStorage::S3ServiceIdempotentDeleteTest < ActiveSupport::TestCase
  test "Delete succeeds when S3 object is already missing (idempotent)" do
    # Create a mock S3 service that raises NoSuchKey on delete
    mock_s3_service = Minitest::Mock.new
    mock_s3_service.expect(:delete, nil, ["missing-object-key"])
    
    # Wrap it with our idempotent wrapper
    wrapper = ActiveStorage::S3ServiceWrapper.new(mock_s3_service)
    
    # Simulate Aws::S3::Errors::NoSuchKey being raised
    mock_s3_service.stub(:delete) do |key|
      raise Aws::S3::Errors::NoSuchKey.new("Not Found", "GetObject")
    end
    
    # This should not raise an exception - delete should succeed idempotently
    assert_nothing_raises do
      wrapper.delete("missing-object-key")
    end
    
    # Verify delete was called
    mock_s3_service.verify
  end

  test "Delete raises other S3 errors (e.g., AccessDenied)" do
    # Create a mock S3 service that raises AccessDenied
    mock_s3_service = Minitest::Mock.new
    mock_s3_service.expect(:delete, nil, ["protected-object-key"])
    
    # Wrap it with our idempotent wrapper
    wrapper = ActiveStorage::S3ServiceWrapper.new(mock_s3_service)
    
    # Simulate Aws::S3::Errors::AccessDenied being raised
    mock_s3_service.stub(:delete) do |key|
      raise Aws::S3::Errors::AccessDenied.new("Access Denied", "GetObject")
    end
    
    # This should raise an exception - AccessDenied should not be rescued
    assert_raises(Aws::S3::Errors::AccessDenied) do
      wrapper.delete("protected-object-key")
    end
    
    # Verify delete was called (even though it raised)
    mock_s3_service.verify
  end

  test "Other operations pass through unchanged" do
    mock_s3_service = Minitest::Mock.new
    
    # Expect various operations to be called
    mock_s3_service.expect(:upload, nil, ["test-key", "test-io", {checksum: "abc123"}])
    mock_s3_service.expect(:download, nil, ["test-key"])
    mock_s3_service.expect(:exist?, true, ["test-key"])
    mock_s3_service.expect(:delete, nil, ["test-key"])
    
    wrapper = ActiveStorage::S3ServiceWrapper.new(mock_s3_service)
    
    # Test upload passes through
    wrapper.upload("test-key", "test-io", checksum: "abc123")
    
    # Test download passes through
    wrapper.download("test-key") do |chunk| end
    
    # Test exist? passes through
    assert wrapper.exist?("test-key")
    
    # Test delete passes through (or rescues NoSuchKey)
    wrapper.delete("test-key")
    
    # Verify all operations were called
    mock_s3_service.verify
  end

  test "Blob.purge succeeds when S3 object is already missing" do
    # Create a blob with a service that will raise NoSuchKey on delete
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      key: "test-blob-key",
      filename: ActiveStorage::Filename.new("test-file.txt"),
      byte_size: 1024,
      checksum: "abc123"
    )
    
    # Mock the S3 service to raise NoSuchKey on delete
    original_service = blob.service
    mock_s3_service = Minitest::Mock.new
    
    mock_s3_service.expect(:delete, nil, ["test-blob-key"])
    mock_s3_service.stub(:delete) do |key|
      raise Aws::S3::Errors::NoSuchKey.new("Not Found", "GetObject")
    end
    
    # Temporarily replace the blob's service
    blob.service = mock_s3_service
    
    # This should succeed even though S3 raises NoSuchKey
    assert_nothing_raises do
      blob.purge
    end
    
    # The blob should be destroyed
    assert blob.destroyed?
  end
end