class ZomatoMoreDetails < ActiveRecord::Migration
  def change
    add_column :zomato_restaurants, :thumb, :string
    add_column :zomato_restaurants, :featured_image, :string
    add_column :zomato_restaurants, :aggregate_rating, :float
    add_column :zomato_restaurants, :rating_text, :string
  end
end
