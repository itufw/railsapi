class AddPackageColumn < ActiveRecord::Migration
  def change
  	add_column :products, :product_package_type_id, :integer
  end
end
