class StaffSalesCalendarRight < ActiveRecord::Migration
  def change
    add_column :staffs, :sales_list_right, :integer
    add_column :staffs, :calendar_right, :integer
  end
end
