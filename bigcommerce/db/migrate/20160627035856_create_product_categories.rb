class CreateProductCategories < ActiveRecord::Migration
  def change
    create_table :product_categories do |t|
      
      t.integer :product_id, :category_id, null: false, unsigned: true, index: true
      t.timestamps null: false
    end
  end
end
