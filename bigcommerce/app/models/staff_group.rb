class StaffGroup < ActiveRecord::Base
  belongs_to :staff
  has_many :items, -> {order :item_model}, class_name: :StaffGroupItem

  def self.personal(user_id)
    where(staff_id: user_id)
  end

  def self.duplicated(user_id, group_name)
    where(staff_id: user_id, group_name: group_name)
  end

  def product_no_ws
    items.where(item_model: 'ProductNoWs')
  end

  def self.staff_groups(staff_id)
    joins(:items).where('staff_groups.staff_id = ? OR (staff_group_items.item_model LIKE "Staff" AND staff_group_items.item_id = ?)', staff_id, staff_id)
  end

  def staffs
    items.where(item_model: 'Staff')
  end
end
