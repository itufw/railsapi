class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses do |t|

      t.text :name, :alt_name, limit: 255
      t.integer :order
      t.integer :in_use, :confirmed, :in_transit, :delivered, :picking, limit: 1

      t.timestamps null: false
    end
  end
end
