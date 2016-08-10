class CreateCustStores < ActiveRecord::Migration
  def change
    create_table :cust_stores do |t|

      t.text :name, limit: 255

      t.timestamps null: false
    end
  end
end
