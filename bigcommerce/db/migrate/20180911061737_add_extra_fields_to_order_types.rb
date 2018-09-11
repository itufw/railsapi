class AddExtraFieldsToOrderTypes < ActiveRecord::Migration
  def change
    add_column :order_types, :item_price_factor, :decimal, scale: 2, precision: 5
    add_column :order_types, :item_wet, :boolean
    add_column :order_types, :item_gst, :boolean
    add_column :order_types, :based_price_deduction, :decimal, scale: 2, precision: 8
  end
end
