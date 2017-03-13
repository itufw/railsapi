class CreateOrderActions < ActiveRecord::Migration
  def change
    create_table :order_actions do |t|
      t.integer :order_id, null: false
      t.string :action, limit: 20, null: false
      t.integer  :task_id

      t.timestamps null: false
    end
  end
end
