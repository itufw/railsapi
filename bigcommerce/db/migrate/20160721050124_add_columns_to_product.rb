class AddColumnsToProduct < ActiveRecord::Migration
  def change
  	add_column :products, :producer_id, :integer
  	add_column :products, :product_type_id, :integer
  	add_column :products, :warehouse_id, :integer
  	add_column :products, :product_size_id, :integer
  	add_column :products, :product_package_id, :integer


  end
end
