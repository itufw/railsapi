class AddReportToToStaff < ActiveRecord::Migration
  def change
    add_column :staffs, :report_to, :integer
  end
end
