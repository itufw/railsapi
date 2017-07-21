class AddGooglePlaceId < ActiveRecord::Migration
  def change
    add_column :customers, :google_place_id, :string
    add_column :customer_leads, :google_place_id, :string
  end
end
