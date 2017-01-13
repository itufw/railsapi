class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :subject, :priority
      t.text :content
      t.timestamp :start_date, :end_date
      # active or completed or deleted or other
      t.string :status
      t.timestamps null: false
    end
  end
end
