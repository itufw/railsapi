class OrderSecondWet < ActiveRecord::Migration
  def change
    add_column :orders, :modified_wet, :float
    add_column :orders, :billing_address, :string
  end
end
