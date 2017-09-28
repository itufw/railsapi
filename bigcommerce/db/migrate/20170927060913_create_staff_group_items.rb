class CreateStaffGroupItems < ActiveRecord::Migration
  def change
    create_table :staff_group_items do |t|
      t.integer :staff_group_id, :item_id
      t.string :item_model
      t.timestamps null: false
    end
  end
end
