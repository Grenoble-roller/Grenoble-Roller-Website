class AddStockReturnedAtToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :stock_returned_at, :datetime
  end
end
