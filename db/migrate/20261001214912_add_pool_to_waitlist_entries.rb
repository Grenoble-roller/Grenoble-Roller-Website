# frozen_string_literal: true

class AddPoolToWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :waitlist_entries, :pool, :string, null: false, default: "member"
    add_index :waitlist_entries, [ :event_id, :pool, :status, :position ],
              name: "index_waitlist_entries_on_event_pool_status_position"
  end
end
