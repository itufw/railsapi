class StaffOrder < ActiveRecord::Migration
  def change
    add_column :staffs, :staff_order, :int
  end
end
