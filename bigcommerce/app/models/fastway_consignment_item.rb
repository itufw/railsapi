class FastwayConsignmentItem < ActiveRecord::Base
  belongs_to :consignment, class_name: 'FastwayConsignment', foreign_key: 'ConsignmentID'
  has_many :traces, class_name: 'FastwayTrace', foreign_key: 'LabelNumber'

  def self.exists?(item_ids)
    where(ItemID: item_ids)
  end

  def self.pending_label(label_numbers)
    return where('LabelNumber NOT IN (?)', label_numbers) unless label_numbers.blank?
    all
  end
end
