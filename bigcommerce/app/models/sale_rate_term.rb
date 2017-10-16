class SaleRateTerm < ActiveRecord::Base
  def self.standard_term
    where(id: [1, 2, 3, 4])
  end

  def self.special_term(group_id)
    where(id: StaffGroupItem.where(staff_group_id: group_id, item_model: 'SaleRateTerm').map(&:item_id))
  end
end
