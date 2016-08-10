class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|

      t.text :sku, :name, limit: 255
      t.integer :inventory, limit: 4
      t.datetime :date_created
      t.decimal :weight, :height, :width, :depth, precision: 20, scale: 2
      t.integer :visible, :featured, limit: 1
      t.text :availability, limit: 20
      t.datetime :date_modified
      t.datetime :date_last_imported
      t.integer :num_sold, :num_viewed, limit: 6
      t.text :upc, :bin_picking_num, :search_keywords, :meta_keywords, :description, :meta_description, :page_title
      t.decimal :retail_price, :sale_price, :calculated_price, precision: 20, scale: 2
      t.integer :inventory_warning_level, limit: 4
      t.text :inventory_tracking, :keyword_filter
      t.integer :sort_order, :related_products, :rating_total, :rating_count

      t.timestamps null: false
    end
  end
end
