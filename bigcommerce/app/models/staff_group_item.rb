class StaffGroupItem < ActiveRecord::Base
  belongs_to :staff_group

  validates_uniqueness_of :item_id, scope: [:staff_group_id, :item_model]

  def self.filter_by_group(group_id)
    where(staff_group_id: group_id)
  end

  def self.products(group_id, product_ids = nil)
    return [] if group_id.nil?
    return where(staff_group_id: group_id, item_model: 'Product') if product_ids.nil?
    where(staff_group_id: group_id, item_id: product_ids, item_model: 'Product')
  end

  def self.productNoWs(group_id, product_ids = nil)
    return [] if group_id.nil?
    return where(staff_group_id: group_id, item_model: 'ProductNoWs') if product_ids.nil?
    where(staff_group_id: group_id, item_id: product_ids, item_model: 'ProductNoWs')
  end
end
