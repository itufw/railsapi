class AddTaskPriorityAccepted < ActiveRecord::Migration
  def change
    add_column :tasks, :priority, :integer, limit: 1
    add_column :tasks, :accepted, :string, limit: 10
  end
end
