class WarehouseExamining < ActiveRecord::Base
  belongs_to :product_no_ws
  belongs_to :creator, class_name: :Staff, foreign_key: :count_staff_id

  def self.duplicated(product_id)
    where(product_no_ws_id: product_id, authorised_date: nil)
  end

  def self.pending
    where(authorised_date: nil)
  end

end
