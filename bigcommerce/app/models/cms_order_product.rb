class CmsOrderProduct < ActiveRecord::Base
  belongs_to :cms_order

  def self.order_products(order_id)
    where(cms_order_id: order_id)
  end
end
