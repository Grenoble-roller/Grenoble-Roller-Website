# frozen_string_literal: true

# Wrapper for ActiveStorage S3 service to make delete operations idempotent.
# Rescues Aws::S3::Errors::NoSuchKey during delete to make purge idempotent
# when the S3 object is already missing, while preserving other S3 errors.
#
# This addresses the issue where ActiveStorage::Blob#purge fails with
# Aws::S3::Errors::NoSuchKey when the S3 object is already absent,
# causing PurgeJob failures in solid_queue_failed_executions.
#
# The wrapper intercepts only the delete operation and rescues NoSuchKey.
# All other operations (upload, download, exist?, etc.) pass through unchanged.
class ActiveStorage::S3ServiceWrapper < ActiveStorage::Service
  # :nodoc:
  attr_reader :wrapped_service

  def initialize(wrapped_service)
    @wrapped_service = wrapped_service
  end

  # Delegate all methods to the wrapped service, intercepting only delete
  def upload(key, io, checksum: nil, **options)
    wrapped_service.upload(key, io, checksum: checksum, **options)
  end

  def download(key, &block)
    wrapped_service.download(key, &block)
  end

  def download_chunk(key, range)
    wrapped_service.download_chunk(key, range)
  end

  # Wrapped delete that rescues Aws::S3::Errors::NoSuchKey
  def delete(key)
    instrument :delete, key: key do
      begin
        wrapped_service.delete(key)
      rescue Aws::S3::Errors::NoSuchKey
        # If the S3 object is already missing, treat as successful
        # idempotent delete - this matches DiskService behavior
      end
    end
  end

  def delete_prefixed(prefix)
    wrapped_service.delete_prefixed(prefix)
  end

  def exist?(key)
    wrapped_service.exist?(key)
  end

  def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
    wrapped_service.url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata:)
  end

  def headers_for_direct_upload(key, content_type:, checksum:, filename: nil, disposition: nil, custom_metadata: {}, **)
    wrapped_service.headers_for_direct_upload(key, content_type:, checksum:, filename:, disposition:, custom_metadata:, **)
  end

  def compose(source_keys, destination_key, filename: nil, content_type: nil, disposition: nil, custom_metadata: {})
    wrapped_service.compose(source_keys, destination_key, filename: filename, content_type: content_type, disposition: disposition, custom_metadata:)
  end

  def public?
    wrapped_service.public?
  end

  def inspect
    "#<#{self.class} wrapped=#{wrapped_service.inspect}>"
  end

  # Delegate all other methods to wrapped service
  def method_missing(method, *args, &block)
    if wrapped_service.respond_to?(method)
      wrapped_service.send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    wrapped_service.respond_to?(method, include_private) || super
  end
end

# Monkey-patch ActiveStorage::Service to wrap S3 services
module ActiveStorage
  class Service
    # Override the build method to wrap S3 services for idempotent deletes
    def self.build(configurator:, name:, service: nil, **service_config)
      # Build the service normally first
      service_instance = configurator.build_service(name, service: service, **service_config)

      # If the service is an S3 service, wrap it with our idempotent delete wrapper
      if service_instance.is_a?(ActiveStorage::Service::S3Service)
        ActiveStorage::S3ServiceWrapper.new(service_instance)
      else
        service_instance
      end
    end
  end
end