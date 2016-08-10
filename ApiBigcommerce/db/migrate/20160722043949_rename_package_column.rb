class RenamePackageColumn < ActiveRecord::Migration
  def change
  	remove_column :products, :product_package_id
  end
end
