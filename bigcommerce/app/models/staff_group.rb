class StaffGroup < ActiveRecord::Base
  belongs_to :staff
  has_many :staff_group_items

  def self.personal(user_id)
    where(staff_id: user_id)
  end

  def self.duplicated(user_id, group_name)
    where(staff_id: user_id, group_name: group_name)
  end
end
