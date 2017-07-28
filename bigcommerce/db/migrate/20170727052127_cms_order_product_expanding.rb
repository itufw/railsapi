class CmsOrderProductExpanding < ActiveRecord::Migration
  def change
    add_column :cms_order_products, :discount, :float
    add_column :cms_order_products, :stock_previous, :integer
    add_column :cms_order_products, :stock_current, :integer
    add_column :cms_order_products, :stock_incremental, :integer
    add_column :cms_order_products, :display, :integer
    add_column :cms_order_products, :damaged, :integer
    add_column :cms_order_products, :note, :text
    add_column :cms_order_products, :created_by, :integer
    add_column :cms_order_products, :modified_by, :integer
  end
end
