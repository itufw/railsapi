class CreateOrderHistories < ActiveRecord::Migration
  def change
    create_table :order_histories do |t|

      t.integer :order_id, unsigned: true, null: false, index: true
      t.datetime :date_created

      t.integer :customer_id, unsigned: true, null: false, index: true

	  t.integer :status_id, unsigned: true, null: false, index: true

	  t.integer :staff_id, index: true, unsigned: true

	  t.decimal :total_inc_tax, :refunded_amount, precision: 20, scale: 2
	  t.integer :qty, limit: 3, unsigned: true, null: false
	  t.integer :items_shipped, limit: 3, unsigned: true
	  t.text :staff_notes, :customer_notes

	  t.integer :billing_address_id, unsigned: true, index: true

	  t.integer :coupon_id, unsigned: true, null: true, limit: 4, index: true

	  t.text :payment_method, limit: 255

	  t.decimal :discount_amount, :coupon_discount, :subtotal_ex_tax, :subtotal_inc_tax,
	   :subtotal_tax, :total_ex_tax, :total_tax, :base_shipping_cost, :shipping_cost_ex_tax,
	   :shipping_cost_inc_tax, :shipping_cost_tax, :base_handling_cost, :handling_cost_ex_tax, :handling_cost_inc_tax,
	   :handling_cost_tax, :base_wrapping_cost, :wrapping_cost_ex_tax, :wrapping_cost_inc_tax,
	   :wrapping_cost_tax, :store_credit, :gift_certificate_amount, precision: 20, scale: 2

	  t.integer :shipping_cost_tax_class_id, :handling_cost_tax_class_id, :wrapping_cost_tax_class_id

	 
	  t.integer :active, limit: 1
	
	  t.text :ip_address
	  t.text :order_source, limit: 255
	  t.datetime :date_modified, :date_shipped
	  
      t.timestamps null: false
    end
  end
end
