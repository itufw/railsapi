class FastwayTrace < ActiveRecord::Base
  belongs_to :item, class_name: 'fastway_consignment_item', foreign_key: 'LabelNumber'
  delegate :consignment, to: :item

  def self.exists?(label_number, description, status_description)
    where(LabelNumber: label_number, Description: description, StatusDescription: status_description)
  end

  def self.completed
    where(Type: 'D', Description: 'Signature Obtained')
  end

  def self.uncompleted
    where('LabelNumber NOT IN (?)', completed.map(&:LabelNumber))
  end

  def self.tract_order(order_id)
    where("Reference LIKE '%#{order_id}%'")
  end
end
