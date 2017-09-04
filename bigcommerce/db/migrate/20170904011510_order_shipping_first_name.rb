class OrderShippingFirstName < ActiveRecord::Migration
  def change
    add_column :orders, :ship_name, :string
  end
end
