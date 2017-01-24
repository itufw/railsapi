class CreateTaskSubjects < ActiveRecord::Migration
  def change
    create_table :task_subjects do |t|
      t.string :subject, :function, :user_type
      t.timestamps null: false
    end
  end
end
