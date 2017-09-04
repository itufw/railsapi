class CreateOrderProductHistories < ActiveRecord::Migration
  def change
    create_table :order_product_histories do |t|
      t.integer :order_id, :order_history_id, :product_id, :order_shipping_id, null: false, unsigned: true, index: true
      t.integer :qty, :qty_shipped, limit: 3, unsigned: true, null: false
	    t.decimal :price_luc, :base_price, :discount, :order_discount,
                :price_handling, :price_inc_tax, :price_wet, :price_gst,
                :price_discounted, null: false, scale: 4, precision: 9
      t.integer :stock_previous, :stock_current, :stock_incremental, :display, :damaged
      t.text :note
      t.integer :created_by, :updated_by

      t.timestamps null: false
    end
  end
end
