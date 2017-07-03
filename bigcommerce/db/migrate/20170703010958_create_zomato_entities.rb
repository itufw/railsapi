class CreateZomatoEntities < ActiveRecord::Migration
  def change
    create_table :zomato_entities do |t|
      t.string :entity_type
      t.integer :entity_id
      t.string :title
      t.float :latitude, :longitude
      t.integer :city_id
      t.string :city_name
      t.integer :country_id
      t.string :country_name
      t.timestamps null: false
    end
  end
end
# "entity_type": "group",
#  "entity_id": "36932",
#  "title": "Chelsea Market, Chelsea, New York City",
#  "latitude": "40.742051",
#  "longitude": "-74.004821",
#  "city_id": "280",
#  "city_name": "New York City",
#  "country_id": "216",
#  "country_name": "United States"
