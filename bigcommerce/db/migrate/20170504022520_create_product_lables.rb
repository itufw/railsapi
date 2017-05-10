class CreateProductLables < ActiveRecord::Migration
  def change
    create_table :product_lables do |t|
      t.string :name, limit: 30, null: false
      t.timestamps null: false
    end
  end
end
