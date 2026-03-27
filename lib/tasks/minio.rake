# frozen_string_literal: true

namespace :minio do
  desc "Ensure Active Storage S3 bucket exists on MinIO (idempotent; no-op if :minio is not the configured service)"
  task ensure_bucket: :environment do
    unless Rails.application.config.active_storage.service.to_sym == :minio
      puts "[minio:ensure_bucket] Skip: active_storage.service=#{Rails.application.config.active_storage.service.inspect} (expected :minio)"
      next
    end

    configs = Rails.application.config.active_storage.service_configurations
    minio_cfg = configs["minio"] || configs[:minio]
    unless minio_cfg
      abort "[minio:ensure_bucket] Missing service configuration for :minio in active_storage.service_configurations"
    end

    bucket = minio_cfg["bucket"] || minio_cfg[:bucket]
    endpoint = minio_cfg["endpoint"] || minio_cfg[:endpoint]
    access_key_id = minio_cfg["access_key_id"] || minio_cfg[:access_key_id]
    secret_access_key = minio_cfg["secret_access_key"] || minio_cfg[:secret_access_key]
    region = minio_cfg["region"] || minio_cfg[:region] || "us-east-1"
    force_path_style = minio_cfg.fetch("force_path_style", minio_cfg.fetch(:force_path_style, true))

    unless bucket.present? && endpoint.present? && access_key_id.present? && secret_access_key.present?
      abort "[minio:ensure_bucket] Incomplete :minio config (bucket, endpoint, access_key_id, secret_access_key required)"
    end

    require "aws-sdk-s3"

    client = Aws::S3::Client.new(
      endpoint: endpoint,
      region: region,
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      force_path_style: force_path_style
    )

    begin
      client.head_bucket(bucket: bucket)
      puts "[minio:ensure_bucket] OK — bucket already exists: #{bucket}"
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
      client.create_bucket(bucket: bucket)
      puts "[minio:ensure_bucket] Created bucket: #{bucket}"
    rescue Aws::S3::Errors::BucketAlreadyOwnedByYou, Aws::S3::Errors::BucketAlreadyExists
      puts "[minio:ensure_bucket] OK — bucket already exists: #{bucket}"
    end
  end
end
