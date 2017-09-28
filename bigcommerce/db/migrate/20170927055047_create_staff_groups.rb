class CreateStaffGroups < ActiveRecord::Migration
  def change
    create_table :staff_groups do |t|
      t.integer :staff_id
      t.string :group_name
      t.timestamps null: false
    end
  end
end
