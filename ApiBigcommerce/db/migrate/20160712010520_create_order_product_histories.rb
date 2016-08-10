class CreateOrderProductHistories < ActiveRecord::Migration
  def change
    create_table :order_product_histories do |t|

      t.integer :order_history_id, :order_id, :product_id, :order_shipping_id, null: false, unsigned: true, index: true
      t.integer :qty, :qty_shipped, limit: 3, unsigned: true, null: false
	  t.decimal :base_price, :price_ex_tax, :price_inc_tax, :price_tax, precision: 20, scale: 2, null: false

      t.timestamps null: false
    end
  end
end
