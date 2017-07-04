class ZomatoRestaurantActiveCustomerTag < ActiveRecord::Migration
  def change
    add_column :zomato_restaurants, :customer_id, :integer
    add_column :zomato_restaurants, :customer_lead_id, :integer
    add_column :zomato_restaurants, :active, :integer
  end
end
