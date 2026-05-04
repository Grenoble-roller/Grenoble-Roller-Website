# frozen_string_literal: true

# Kept for backward compatibility — delegates to storage:ensure_bucket.
# Use `rake storage:ensure_bucket` directly.
namespace :minio do
  task ensure_bucket: "storage:ensure_bucket"
end

namespace :storage do
  desc "Ensure Active Storage S3 bucket exists (idempotent; skips if service is not S3-compatible)"
  task ensure_bucket: :environment do
    service_name = Rails.application.config.active_storage.service
    configs = Rails.application.config.active_storage.service_configurations
    cfg = configs[service_name.to_s] || configs[service_name]

    unless cfg && cfg["service"] == "S3"
      puts "[storage:ensure_bucket] Skip: service=#{service_name.inspect} is not S3-compatible"
      next
    end

    bucket         = cfg["bucket"]
    endpoint       = cfg["endpoint"]
    access_key_id  = cfg["access_key_id"]
    secret_key     = cfg["secret_access_key"]
    region         = cfg["region"] || "us-east-1"
    path_style     = cfg.fetch("force_path_style", true)

    unless bucket.present? && endpoint.present? && access_key_id.present? && secret_key.present?
      abort "[storage:ensure_bucket] Incomplete S3 config — bucket, endpoint, access_key_id, secret_access_key are required"
    end

    require "aws-sdk-s3"

    client = Aws::S3::Client.new(
      endpoint:          endpoint,
      region:            region,
      access_key_id:     access_key_id,
      secret_access_key: secret_key,
      force_path_style:  path_style
    )

    begin
      client.head_bucket(bucket: bucket)
      puts "[storage:ensure_bucket] OK — bucket exists: #{bucket}"
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
      client.create_bucket(bucket: bucket)
      puts "[storage:ensure_bucket] Created bucket: #{bucket}"
    rescue Aws::S3::Errors::BucketAlreadyOwnedByYou, Aws::S3::Errors::BucketAlreadyExists
      puts "[storage:ensure_bucket] OK — bucket exists: #{bucket}"
    end
  end
end
