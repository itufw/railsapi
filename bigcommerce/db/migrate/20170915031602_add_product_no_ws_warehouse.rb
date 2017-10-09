class AddProductNoWsWarehouse < ActiveRecord::Migration
  def change
    add_column :product_no_ws, :selected, :integer
    add_column :product_no_ws, :warehouse_id, :integer
    add_column :product_no_ws, :row, :string
    add_column :product_no_ws, :column, :string
    add_column :product_no_ws, :area, :string
  end
end
