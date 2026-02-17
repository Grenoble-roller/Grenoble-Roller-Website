# frozen_string_literal: true

class AddUniquePositionToHomepageCarousels < ActiveRecord::Migration[7.2]
  def up
    # Normaliser les positions existantes : attribuer 1, 2, 3, ... par ordre (position, created_at)
    # pour supprimer les doublons avant d'ajouter l'index unique
    ids = connection.select_values("SELECT id FROM homepage_carousels ORDER BY position ASC, created_at DESC")
    ids.each_with_index do |id, index|
      connection.execute("UPDATE homepage_carousels SET position = #{index + 1} WHERE id = #{connection.quote(id)}")
    end

    remove_index :homepage_carousels, name: "index_homepage_carousels_on_position" if index_exists?(:homepage_carousels, :position, name: "index_homepage_carousels_on_position")
    add_index :homepage_carousels, :position, unique: true, name: "index_homepage_carousels_on_position_unique"
  end

  def down
    remove_index :homepage_carousels, name: "index_homepage_carousels_on_position_unique" if index_exists?(:homepage_carousels, :position, name: "index_homepage_carousels_on_position_unique")
    add_index :homepage_carousels, :position, name: "index_homepage_carousels_on_position"
  end
end
