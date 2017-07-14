class CreateZomatoCuisines < ActiveRecord::Migration
  def change
    create_table :zomato_cuisines do |t|
      t.string :name
      t.integer :active
      t.timestamps null: false
    end
  end
end
