class CreateZomatoRestaurants < ActiveRecord::Migration
  def change
    create_table :zomato_restaurants do |t|
      # URL of the restaurant page
      t.string :name, :url, :address, :locality
      t.float :latitude, :longitude
      t.string :zipcode
      t.integer :country_id, :average_cost_for_two
      t.string :cuisines

      t.timestamps null: false
    end
  end
end
