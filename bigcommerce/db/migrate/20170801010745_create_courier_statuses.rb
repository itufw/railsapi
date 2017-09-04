class CreateCourierStatuses < ActiveRecord::Migration
  def change
    create_table :courier_statuses do |t|
      t.text :name, :alt_name, limit: 255
      t.integer :order
      t.integer :in_use, :confirmed, :send_reminder, :can_update, limit: 1
      t.text :description
      t.timestamps null: false
    end
  end
end
