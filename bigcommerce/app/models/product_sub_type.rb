class ProductSubType < ActiveRecord::Base
  belongs_to :product_type
  has_many :products

  def self.product_type_filter(type_id)
  	return where(product_type_id: type_id) if type_id
  	return all
  end
end
