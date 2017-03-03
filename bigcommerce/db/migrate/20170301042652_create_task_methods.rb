class CreateTaskMethods < ActiveRecord::Migration
  def change
    create_table :task_methods do |t|
      t.string :method, null: false, index: true

      t.timestamps null: false
    end
  end
end
