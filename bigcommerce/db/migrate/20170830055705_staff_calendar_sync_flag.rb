class StaffCalendarSyncFlag < ActiveRecord::Migration
  def change
    add_column :staff_calendar_addresses, :sync_calendar, :integer
  end
end
