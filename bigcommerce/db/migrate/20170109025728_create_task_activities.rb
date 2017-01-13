class CreateTaskActivities < ActiveRecord::Migration
  def change
    create_table :task_activities do |t|
      t.integer :task_id
      t.text :log
      t.timestamps null: false
    end
  end
end
