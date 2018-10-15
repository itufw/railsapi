class AddTypesToOrderType < ActiveRecord::Migration
  def change
    add_column :order_types, :sale_type, :string, limit: 9
    add_column :order_types, :product_type, :string, limit: 9
  end
end
