class AddHiddenWetToOrderTypes < ActiveRecord::Migration
  def change
    add_column :order_types, :hidden_wet_price_factor, :decimal, scale: 2, precision: 5
  end
end
