class RenameVarietalTable < ActiveRecord::Migration
  def change
  	rename_table :product_varietals, :product_sub_types
  	rename_table :product_packages, :product_package_types
  end
end
