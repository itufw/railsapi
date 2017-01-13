class CreateTaskRelations < ActiveRecord::Migration
  def change
    create_table :task_relations do |t|
      t.integer :task_id, :contact_id, :customer_id, :cust_group_id, :staff_id
      # Customer / Customer Groups / Contact
      t.integer :type

      t.timestamps null: false
    end
  end
end
