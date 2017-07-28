class FastwayConsignmentItem < ActiveRecord::Base
  belongs_to :consignment, class_name: 'FastwayConsignment', foreign_key: 'ConsignmentID'

  def self.exists?(item_ids)
    where(ItemID: item_ids)
  end

  def self.filter_order(order_id)
    where("Reference LIKE '%#{order_id}%'")
  end

  def self.pending_label(label_numbers)
    return where('LabelNumber NOT IN (?)', label_numbers) unless label_numbers.blank?
    all
  end

  def traces
    FastwayTrace.trace_label(self.LabelNumber)
  end
end
