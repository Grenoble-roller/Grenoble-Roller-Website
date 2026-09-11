# frozen_string_literal: true

# This initializer sets up ActiveStorage to use the S3 service wrapper
# for idempotent deletes when S3 objects are already missing
Rails.application.config.after_initialize do
  # Get the existing S3 service configuration from storage.yml
  # and wrap it with our idempotent delete wrapper
  storage_config = Rails.application.config.active_storage

  # The service is already configured by Rails during initialization
  # We need to intercept the service configuration process
  # by wrapping the S3 service when it's being built

  # Monkey-patch ActiveStorage::Service to use our wrapper
  original_build = ActiveStorage::Service.method(:build)

  ActiveStorage::Service.define_method(:build) do |configurator:, name:, service: nil, **service_config|
    # Build the service normally first
    service_instance = original_build.bind_call(self, configurator:, name:, service:, **service_config)

    # If the service is an S3 service, wrap it with our idempotent delete wrapper
    if service_instance.is_a?(ActiveStorage::Service::S3Service)
      ActiveStorage::S3ServiceWrapper.new(service_instance)
    else
      service_instance
    end
  end
end