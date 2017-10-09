class AddGroupItemIndex < ActiveRecord::Migration
  def change
    add_index :staff_group_items, [:staff_group_id, :item_id, :item_model], unique: true, name: 'index_staff_group_items'
  end
end
