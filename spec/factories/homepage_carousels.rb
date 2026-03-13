# frozen_string_literal: true

FactoryBot.define do
  factory :homepage_carousel do
    sequence(:title) { |n| "Slide #{n}" }
    subtitle { 'Sous-titre du slide' }
    link_url { nil }
    sequence(:position) { |n| n }
    published { false }
    published_at { nil }
    expires_at { nil }

    trait :with_image do
      after(:build) do |carousel|
        unless carousel.image.attached?
          test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
          FileUtils.mkdir_p(test_image_path.dirname)
          unless File.exist?(test_image_path)
            # Minimal valid JPEG (1x1 pixel)
            jpeg_data = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\f\x14\r\f\x0B\x0B\f\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\xAA\xFF\xD9"
            File.binwrite(test_image_path, jpeg_data)
          end
          carousel.image.attach(
            io: File.open(test_image_path),
            filename: 'test-image.jpg',
            content_type: 'image/jpeg'
          )
        end
      end
    end

    trait :active do
      published { true }
      published_at { 1.day.ago }
      expires_at { nil }
    end
  end
end
