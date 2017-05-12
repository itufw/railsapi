class LeadLatLonAdd < ActiveRecord::Migration
  def change
    add_column :customer_leads, :latitude, :float
    add_column :customer_leads, :longitude, :float
    add_column :customer_leads, :address, :text
  end
end
