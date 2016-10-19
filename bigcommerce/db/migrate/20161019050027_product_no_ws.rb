class ProductNoWs < ActiveRecord::Migration
  def change
  	add_column :products, :product_no_ws_id, :integer, index: true
  end
end
