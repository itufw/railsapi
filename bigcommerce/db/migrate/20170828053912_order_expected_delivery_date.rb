class OrderExpectedDeliveryDate < ActiveRecord::Migration
  def change
    add_column :orders, :eta, :datetime
  end
end
