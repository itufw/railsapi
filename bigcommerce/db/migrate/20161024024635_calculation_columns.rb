class CalculationColumns < ActiveRecord::Migration
  def change
  	#remove_column :xero_calculations, :gst
  	add_column :xero_calculations, :total_inc_gst, :decimal, precision: 8, scale: 2
  	add_column :xero_calculations, :rounding_error_inc_gst, :decimal, precision: 8, scale: 2
  end
end
