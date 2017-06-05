class CreateStaffCalendarAddresses < ActiveRecord::Migration
  def change
    create_table :staff_calendar_addresses do |t|
      t.integer :staff_id, index: true
      t.text :calendar_address
      t.timestamps null: false
    end
  end
end
