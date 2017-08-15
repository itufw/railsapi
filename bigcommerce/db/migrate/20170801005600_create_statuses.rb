class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses do |t|
      t.text :name, :alt_name, limit: 255
      t.integer :order
      t.integer :in_use, :confirmed, :in_transit, :delivered, :picking,
                :valid_order, :xero_import, :send_reminder, :can_update, limit: 1
      t.text :description
      t.integer :bigcommerce_id
      t.string :bigcommerce_name
      t.timestamps null: false
    end
  end
end
