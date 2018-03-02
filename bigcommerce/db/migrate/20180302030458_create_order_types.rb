class CreateOrderTypes < ActiveRecord::Migration
  def change
    create_table :order_types do |t|

      t.timestamps null: false
    end
  end
end
