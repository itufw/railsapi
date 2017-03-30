class AddLatLngGToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :lat, :decimal, scale: 7, precision: 12
    add_column :addresses, :lng, :decimal, scale: 7, precision: 12

  end
end
