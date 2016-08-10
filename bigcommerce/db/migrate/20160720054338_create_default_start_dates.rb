class CreateDefaultStartDates < ActiveRecord::Migration
  def change
    create_table :default_start_dates do |t|

      t.integer :staff_id
      t.date :default_date
      t.timestamps null: false
    end
  end
end
