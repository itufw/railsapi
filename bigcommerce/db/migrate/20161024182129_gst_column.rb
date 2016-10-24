class GstColumn < ActiveRecord::Migration
  def change
  	remove_column :xero_calculations, :total_inc_gst
  	add_column :xero_calculations, :gst, :decimal, precision: 8, scale: 2
  end
end
