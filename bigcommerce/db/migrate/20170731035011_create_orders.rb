class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :customer_id, unsigned: true, null: false, index: true

      t.integer :status_id, index: true, unsigned: true

      t.integer :staff_id, index: true, unsigned: true

      t.decimal :total_inc_tax, scale: 4, precision: 10

      t.integer :qty, limit: 3, unsigned: true, null: false
      t.integer :items_shipped, limit: 3, unsigned: true

      t.decimal :subtotal, :discount_rate, :discount_amount,
        :handling_cost, :shipping_cost, :wrapping_cost, :wet, :gst, scale: 4, precision: 10

      t.text :staff_notes, :customer_notes

      t.integer :active, limit: 1

      t.string  :xero_invoice_id, :xero_invoice_number, :source, :source_id

      t.datetime :date_created, :date_shipped

      t.integer :created_by, :last_updated_by
      t.timestamps null: false
    end
  end
end
