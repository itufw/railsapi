class CreateTaskPriorities < ActiveRecord::Migration
  def change
    create_table :task_priorities do |t|
      t.string :priority_level, limit: 20, null:false

      t.timestamps null: false
    end
  end
end
