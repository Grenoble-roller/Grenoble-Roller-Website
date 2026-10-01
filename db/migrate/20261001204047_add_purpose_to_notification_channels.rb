# frozen_string_literal: true

class AddPurposeToNotificationChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_channels, :purpose, :string
    add_index :notification_channels, :purpose, unique: true, where: "purpose IS NOT NULL"
  end
end
