class CreateOrderTypes < ActiveRecord::Migration
  def change
    create_table :order_types do |t|
      t.string :name, limit: 3
      t.string :description, limit: 120
      t.timestamps null: false
    end
  end
end
