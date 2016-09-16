class ProductSubType < ActiveRecord::Base
  belongs_to :product_type
  has_many :products

  def self.filter_by_id(id)
  	find(id)
  end
end
