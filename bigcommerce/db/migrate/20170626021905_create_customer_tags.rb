class CreateCustomerTags < ActiveRecord::Migration
  def change
    create_table :customer_tags do |t|
      t.string :name, :role
      t.integer :customer_id
      t.timestamps null: false
    end
  end
end
