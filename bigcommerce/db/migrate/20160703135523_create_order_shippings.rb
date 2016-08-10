class CreateOrderShippings < ActiveRecord::Migration
  def change
    create_table :order_shippings do |t|
      t.integer :order_id, :address_id, null: false, unsigned: true, index: true
      t.integer :items_total, :items_shipped
      t.timestamps null: false
    end
  end
end
