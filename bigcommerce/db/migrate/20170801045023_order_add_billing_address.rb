class OrderAddBillingAddress < ActiveRecord::Migration
  def change
    add_column :orders, :street, :text
    add_column :orders, :city, :string
    add_column :orders, :state, :string
    add_column :orders, :postcode, :string
    add_column :orders, :country, :string
    add_column :orders, :address, :string
  end
end
