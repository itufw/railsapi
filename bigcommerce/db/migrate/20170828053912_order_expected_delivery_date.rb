class OrderExpectedDeliveryDate < ActiveRecord::Migration
  def change
    add_column :orders, :expected_delivery_date, :datetime
  end
end
