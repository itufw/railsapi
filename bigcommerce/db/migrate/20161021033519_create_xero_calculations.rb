class CreateXeroCalculations < ActiveRecord::Migration
  def change
    create_table :xero_calculations do |t|
      t.string :invoice_number, :item_code, :description
      t.integer :qty
      t.decimal :unit_price_inc_tax, :discount_rate, :discounted_unit_price, :discounted_ex_gst_unit_price,\
      :discounted_ex_taxes_unit_price, :line_amount_ex_taxes, precision: 10, scale: 4
      t.decimal :line_amount_ex_taxes_rounded, precision: 8, scale: 2
      t.decimal :wet_unadjusted_order_product_price, :wet_unadjusted_total,\
      :ship_deduction, :subtotal_ex_gst, :wet_adjusted, :adjustment, precision: 10, scale: 4 
      t.decimal :shipping_ex_gst, :total_ex_gst, :gst,\
      :order_total, :rounding_error, precision: 8, scale: 2
      t.string :account_code, :tax_type

      t.timestamps null: false
    end
  end
end
