class OrderReference < ActiveRecord::Migration
  def change
    add_column :orders, :customer_purchase_order, :string
  end
end
