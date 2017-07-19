class CmsOrder < ActiveRecord::Base
  has_many :cms_order_products
end
