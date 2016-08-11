class CreateProducerCountries < ActiveRecord::Migration
  def change
    create_table :producer_countries do |t|

      t.string :name, :short_name

      t.timestamps null: false
    end
  end
end
