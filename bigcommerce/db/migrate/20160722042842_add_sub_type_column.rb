class AddSubTypeColumn < ActiveRecord::Migration
  def change
  	add_column :products, :product_sub_type_id, :integer
  end
end
