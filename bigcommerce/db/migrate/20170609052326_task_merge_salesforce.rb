class TaskMergeSalesforce < ActiveRecord::Migration
  def change
    add_column :tasks, :salesforce_task_id, :string
  end
end
