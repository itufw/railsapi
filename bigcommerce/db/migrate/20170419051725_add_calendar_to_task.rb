class AddCalendarToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :google_event_id, :string
    add_column :tasks, :gcal_status, :integer

  end
end
