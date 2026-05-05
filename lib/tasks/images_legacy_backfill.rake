# frozen_string_literal: true

require "open-uri"

namespace :images do
  desc "Report remaining legacy image_url records (products and variants)"
  task report_legacy_urls: :environment do
    products_count = Product.where.not(image_url: [ nil, "" ]).count
    variants_count = ProductVariant.where.not(image_url: [ nil, "" ]).count

    puts "Legacy image_url report"
    puts "- Products with image_url: #{products_count}"
    puts "- Variants with image_url: #{variants_count}"
  end

  desc "Backfill legacy image_url into Active Storage (DRY_RUN=true by default)"
  task backfill_legacy_urls: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"
    timeout_s = ENV.fetch("OPEN_TIMEOUT", "8").to_i

    puts "Backfill legacy image_url -> Active Storage (dry_run=#{dry_run})"

    product_migrated = 0
    variant_migrated = 0
    failures = []

    Product.where.not(image_url: [ nil, "" ]).find_each do |product|
      next if product.image.attached?

      begin
        io, filename, content_type = fetch_image_from_legacy_url(product.image_url, timeout_s)
        if dry_run
          puts "[DRY-RUN] Product ##{product.id} would attach #{filename}"
        else
          product.image.attach(io: io, filename: filename, content_type: content_type)
          product.update_column(:image_url, nil)
        end
        product_migrated += 1
      rescue StandardError => e
        failures << "Product ##{product.id}: #{e.message}"
      end
    end

    ProductVariant.where.not(image_url: [ nil, "" ]).find_each do |variant|
      next if variant.images.attached?

      begin
        io, filename, content_type = fetch_image_from_legacy_url(variant.image_url, timeout_s)
        if dry_run
          puts "[DRY-RUN] Variant ##{variant.id} would attach #{filename}"
        else
          variant.images.attach(io: io, filename: filename, content_type: content_type)
          variant.update_column(:image_url, nil)
        end
        variant_migrated += 1
      rescue StandardError => e
        failures << "Variant ##{variant.id}: #{e.message}"
      end
    end

    puts "Backfill summary"
    puts "- Products migrated: #{product_migrated}"
    puts "- Variants migrated: #{variant_migrated}"
    puts "- Failures: #{failures.count}"
    failures.each { |line| puts "  * #{line}" } if failures.any?
  end

  def fetch_image_from_legacy_url(legacy_url, timeout_s)
    raise ArgumentError, "empty legacy URL" if legacy_url.blank?

    if legacy_url.start_with?("http://", "https://")
      io = URI.open(legacy_url, read_timeout: timeout_s, open_timeout: timeout_s)
      filename = File.basename(URI.parse(legacy_url).path).presence || "legacy-image"
      [ io, filename, io.content_type || "image/jpeg" ]
    else
      base_path = Rails.root.join("app/assets/images")
      local_path = base_path.join(legacy_url)
      raise "local image not found: #{local_path}" unless File.exist?(local_path)

      io = File.open(local_path, "rb")
      content_type = Marcel::MimeType.for(Pathname(local_path))
      [ io, File.basename(local_path), content_type || "image/jpeg" ]
    end
  end
end
