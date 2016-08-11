class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|

      t.integer :parent_id, unsigned: true, index: true

      t.text :name, limit: 255

      t.text :description

      t.integer :visible, limit: 1

      t.integer :sort_order

      t.text :page_title, :meta_keywords, :meta_description, :search_keywords, :url

      t.timestamps null: false
    end
  end
end
