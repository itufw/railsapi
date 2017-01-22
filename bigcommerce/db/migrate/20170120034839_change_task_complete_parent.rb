class ChangeTaskCompleteParent < ActiveRecord::Migration
  def change
    add_column :tasks, :parent_task, :integer, index: true
    add_column :tasks, :completed_date, :datetime, index: true
    add_column :tasks, :completed_staff, :integer, index: true

    add_column :tasks, :subject_1, :string, index: true
    add_column :tasks, :subject_2, :string, index: true
    add_column :tasks, :subject_3, :string, index: true

  end
end
