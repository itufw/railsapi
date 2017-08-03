class OrderProductUpdate < ActiveRecord::Migration
  def change
    add_column :order_products, :price_luc, :float
    add_column :order_products, :discount, :integer
    add_column :order_products, :order_discount, :integer
    add_column :order_products, :price, :float
    add_column :order_products, :price_ex_transport, :float
    add_column :order_products, :stock_previous, :integer
    add_column :order_products, :stock_current, :integer
    add_column :order_products, :stock_incremental, :integer
    add_column :order_products, :display, :integer
    add_column :order_products, :damaged, :integer
    add_column :order_products, :note, :text
    add_column :order_products, :created_by, :integer
    add_column :order_products, :modified_by, :integer
    add_column :order_products, :price_discounted, :float
  end
end
