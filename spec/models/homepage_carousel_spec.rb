# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomepageCarousel, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'validations' do
    it 'is valid with title, position, and no image when not published' do
      carousel = build(:homepage_carousel, title: 'Test', position: 1, published: false)
      expect(carousel).to be_valid
    end

    it 'requires title' do
      carousel = build(:homepage_carousel, title: nil)
      expect(carousel).to be_invalid
      expect(carousel.errors[:title]).to be_present
    end

    it 'requires position' do
      carousel = build(:homepage_carousel, position: nil)
      expect(carousel).to be_invalid
      expect(carousel.errors[:position]).to be_present
    end

    it 'requires position to be unique' do
      create(:homepage_carousel, position: 1)
      dup = build(:homepage_carousel, position: 1)
      expect(dup).to be_invalid
      expect(dup.errors[:position]).to be_present
    end

    it 'requires position to be an integer >= 0' do
      expect(build(:homepage_carousel, position: -1)).to be_invalid
      expect(build(:homepage_carousel, position: 0)).to be_valid
      expect(build(:homepage_carousel, position: 1.5)).to be_invalid
    end

    it 'requires image when published' do
      carousel = build(:homepage_carousel, published: true, position: 1)
      expect(carousel).to be_invalid
      expect(carousel.errors[:image]).to be_present
    end

    it 'is valid when published with image attached' do
      carousel = build(:homepage_carousel, :with_image, published: true, position: 1)
      expect(carousel).to be_valid
    end
  end

  describe 'scopes' do
    it 'published returns only records with published: true' do
      pub = create(:homepage_carousel, :with_image, published: true, position: 1)
      create(:homepage_carousel, published: false, position: 2)
      expect(described_class.published).to contain_exactly(pub)
    end

    it 'active returns published and not expired, or in published_at window and not expired' do
      travel_to(Time.zone.local(2025, 6, 15, 12)) do
        active_pub = create(:homepage_carousel, :with_image, published: true, position: 1, expires_at: 1.week.from_now)
        expired = create(:homepage_carousel, :with_image, published: true, position: 2, expires_at: 1.day.ago)
        in_window = create(:homepage_carousel, published: false, position: 3, published_at: 1.day.ago, expires_at: 1.week.from_now)
        expect(described_class.active).to contain_exactly(active_pub, in_window)
        expect(described_class.active).not_to include(expired)
      end
    end

    it 'ordered returns by position asc, then created_at desc' do
      c1 = create(:homepage_carousel, position: 3, title: 'Third')
      c2 = create(:homepage_carousel, position: 1, title: 'First')
      c3 = create(:homepage_carousel, position: 2, title: 'Second')
      expect(described_class.ordered.pluck(:id)).to eq([ c2.id, c3.id, c1.id ])
    end
  end

  describe '#active?' do
    it 'returns true when published and not expired' do
      carousel = build(:homepage_carousel, published: true, expires_at: 1.day.from_now)
      expect(carousel.active?).to be true
    end

    it 'returns false when published but expired' do
      carousel = build(:homepage_carousel, published: true, expires_at: 1.day.ago)
      expect(carousel.active?).to be false
    end

    it 'returns true when not published but in published_at window and not expired' do
      carousel = build(:homepage_carousel, published: false, published_at: 1.day.ago, expires_at: 1.week.from_now)
      expect(carousel.active?).to be true
    end
  end

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      carousel = build(:homepage_carousel, expires_at: 1.day.ago)
      expect(carousel.expired?).to be true
    end

    it 'returns false when expires_at is nil or in the future' do
      expect(build(:homepage_carousel, expires_at: nil).expired?).to be false
      expect(build(:homepage_carousel, expires_at: 1.day.from_now).expired?).to be false
    end
  end

  describe 'callbacks' do
    it 'sets default position on create when position is nil' do
      create(:homepage_carousel, position: 10)
      carousel = build(:homepage_carousel, title: 'New', position: nil)
      carousel.save(validate: false)
      expect(carousel.position).to eq(11)
    end

    it 'sets published_at when published is set to true and published_at was nil' do
      carousel = create(:homepage_carousel, :with_image, published: false, published_at: nil)
      carousel.update!(published: true)
      expect(carousel.published_at).to be_present
    end
  end
end
