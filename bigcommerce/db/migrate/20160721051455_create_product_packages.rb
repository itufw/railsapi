class CreateProductPackages < ActiveRecord::Migration
  def change
    create_table :product_packages do |t|

      t.string :name

      t.timestamps null: false
    end
  end
end
