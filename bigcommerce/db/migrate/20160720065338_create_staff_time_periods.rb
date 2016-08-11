class CreateStaffTimePeriods < ActiveRecord::Migration
  def change
    create_table :staff_time_periods do |t|

      t.integer :staff_id
      t.string :name
      t.integer :start_day
      t.integer :end_day
      t.date :start_date
      t.date :end_date
      t.integer :time_period_type, :display, limit: 1
      t.integer :order
      t.string :update_function
      t.timestamps null: false
    end
  end
end
