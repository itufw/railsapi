class FastwayTrace < ActiveRecord::Base
  belongs_to :item, class_name: 'fastway_consignment_item', foreign_key: 'LabelNumber', primary_key: 'LabelNumber'
  delegate :consignment, to: :item

  def self.exists?(label_number, description, status_description)
    where(LabelNumber: label_number, Description: description, StatusDescription: status_description)
  end

  def self.completed
    where(Type: 'D', Description: ['Signature Obtained', 'Left As Instructed', 'Left with neighbour', 'Delivery Completed', 'Authority to Leave'])
  end

  def self.uncompleted
    where('LabelNumber NOT IN (?)', completed.map(&:LabelNumber))
  end

  def self.trace_label(label_number)
    where(LabelNumber: label_number)
  end

  def self.pod_available(invoice_number)
    where("Description IN (?) AND Reference LIKE '%#{invoice_number}%'", ['Signature Obtained', 'Left As Instructed', 'Left with neighbour', 'Delivery Completed', 'Authority to Leave'])
  end

  def self.tract_order(order_id)
    where("Reference LIKE '%#{order_id}%'")
  end

  def self.lastest
    order('Date DESC').limit(1)
  end
end
