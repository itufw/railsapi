class ChangeTaskTableColumn < ActiveRecord::Migration
  def change
    remove_column :tasks, :priority

    remove_column :tasks, :subject
    add_column :tasks, :title, :string, index: true

    remove_column :tasks, :content
    add_column :tasks, :description, :string, index: true

    remove_column :tasks, :status
    add_column :tasks, :is_task, :integer, index: true

    add_column :tasks, :response_staff, :integer, index: true
    add_column :tasks, :last_modified_staff, :integer, index: true
    add_column :tasks, :method, :string, index: true
    add_column :tasks, :categorise, :string, index: true

  end
end
