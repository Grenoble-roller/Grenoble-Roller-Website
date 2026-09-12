# frozen_string_literal: true

require "rails_helper"
require "aws-sdk-s3"

RSpec.describe ActiveStorage::S3ServiceWrapper, type: :service do
  describe "#delete" do
    it "rescues Aws::S3::Errors::NoSuchKey (idempotent delete)" do
      mock_s3_service = double("ActiveStorage::Service")
      allow(mock_s3_service).to receive(:delete)

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:delete).with("missing-object-key") do
        raise Aws::S3::Errors::NoSuchKey.new("Not Found", "GetObject")
      end

      # Should not raise — delete succeeds idempotently when object is already missing
      expect { wrapper.delete("missing-object-key") }.not_to raise_error

      expect(mock_s3_service).to have_received(:delete).with("missing-object-key")
    end

    it "propagates AccessDenied errors (not rescued)" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:delete).with("protected-object-key") do
        raise Aws::S3::Errors::AccessDenied.new("Access Denied", "GetObject")
      end

      # AccessDenied must NOT be rescued
      expect { wrapper.delete("protected-object-key") }.to raise_error(Aws::S3::Errors::AccessDenied)
    end

    it "propagates NetworkingError errors (not rescued)" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      # Use a non-NoSuchKey error to verify only NoSuchKey is rescued
      allow(mock_s3_service).to receive(:delete).with("network-error-key") do
        raise StandardError.new("connection refused")
      end

      expect { wrapper.delete("network-error-key") }.to raise_error(StandardError, "connection refused")
    end

    it "propagates 5xx server errors (not rescued)" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:delete).with("server-error-key") do
        raise Aws::S3::Errors::InternalError.new("Internal Error", "DeleteObject")
      end

      expect { wrapper.delete("server-error-key") }.to raise_error(Aws::S3::Errors::InternalError)
    end
  end

  describe "#upload" do
    it "delegates upload to the wrapped service" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:upload)

      wrapper.upload("test-key", "test-io", checksum: "abc123")

      expect(mock_s3_service).to have_received(:upload).with("test-key", "test-io", checksum: "abc123")
    end
  end

  describe "#download" do
    it "delegates download to the wrapped service" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:download) do |_key, &block|
        block&.call("file-content")
      end

      chunks = []
      wrapper.download("test-key") { |chunk| chunks << chunk }

      expect(mock_s3_service).to have_received(:download)
      expect(chunks).to eq([ "file-content" ])
    end
  end

  describe "#exist?" do
    it "delegates exist? to the wrapped service" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:exist?).with("test-key").and_return(true)

      result = wrapper.exist?("test-key")

      expect(result).to be true
      expect(mock_s3_service).to have_received(:exist?).with("test-key")
    end
  end

  describe "#method_missing" do
    it "delegates unknown methods to the wrapped service" do
      mock_s3_service = double("ActiveStorage::Service")

      wrapper = described_class.new(mock_s3_service)

      allow(mock_s3_service).to receive(:some_custom_method).and_return("custom_result")

      result = wrapper.some_custom_method

      expect(result).to eq("custom_result")
      expect(mock_s3_service).to have_received(:some_custom_method)
    end
  end

  describe "Blob.purge" do
    it "succeeds when S3 object is already missing" do
      # Create a mock S3 service and wrap it — simulates what the Configurator
      # monkey-patch does for real S3Service instances in production.
      mock_s3_service = double("ActiveStorage::Service::S3Service")

      allow(mock_s3_service).to receive(:delete).with("test-blob-key") do
        raise Aws::S3::Errors::NoSuchKey.new("Not Found", "GetObject")
      end

      wrapper = described_class.new(mock_s3_service)

      # Simulate blob.purge calling service.delete through the wrapper
      expect { wrapper.delete("test-blob-key") }.not_to raise_error

      expect(mock_s3_service).to have_received(:delete).with("test-blob-key")
    end
  end
end
