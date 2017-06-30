class CustomerAddLatLng < ActiveRecord::Migration
  def change
    add_column :customers, :lat, :float
    add_column :customers, :lng, :float
  end
end
