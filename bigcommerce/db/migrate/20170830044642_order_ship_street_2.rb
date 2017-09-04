class OrderShipStreet2 < ActiveRecord::Migration
  def change
    add_column :orders, :street_2, :string
  end
end
