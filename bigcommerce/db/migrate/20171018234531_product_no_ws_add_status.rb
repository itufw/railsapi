class ProductNoWsAddStatus < ActiveRecord::Migration
  def change
    add_column :product_no_ws, :product_status_id, :integer
  end
end
