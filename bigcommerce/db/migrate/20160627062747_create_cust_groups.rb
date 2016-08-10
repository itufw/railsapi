class CreateCustGroups < ActiveRecord::Migration
  def change
    create_table :cust_groups do |t|

      t.text :name, limit: 255

      t.timestamps null: false
    end
  end
end
