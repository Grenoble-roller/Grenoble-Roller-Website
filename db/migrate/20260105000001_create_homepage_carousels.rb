class CreateHomepageCarousels < ActiveRecord::Migration[8.1]
  def change
    create_table :homepage_carousels do |t|
      t.string :title, null: false
      t.string :subtitle
      t.string :link_url
      t.integer :position, default: 0
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :homepage_carousels, :position
    add_index :homepage_carousels, :published
    add_index :homepage_carousels, [:published, :expires_at]
  end
end
