class CreateProducerRegions < ActiveRecord::Migration
  def change
    create_table :producer_regions do |t|

      t.string :name
      t.integer :producer_country_id

      t.timestamps null: false
    end
  end
end
