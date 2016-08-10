class AddProducerToProduct < ActiveRecord::Migration
  def change
  	add_column :products, :producer_country_id, :integer
  	add_column :products, :producer_region_id, :integer
  end
end
