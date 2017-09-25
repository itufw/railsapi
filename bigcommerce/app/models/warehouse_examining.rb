class WarehouseExamining < ActiveRecord::Base
  belongs_to :product_no_ws

  def self.duplicated(product_id)
    where(product_no_ws_id: product_id)
  end

  def self.pending
    where(authorised_date: nil)
  end
end
