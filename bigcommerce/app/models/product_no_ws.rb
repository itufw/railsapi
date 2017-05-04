# No WS class for products
class ProductNoWs < ActiveRecord::Base
  has_many :products

  def self.filter_by_ids(ids_a)
    where('id IN (?)', ids_a)
  end

  def self.order_by_name(direction)
    order('name ' + direction)
  end

  def self.order_by_id(direction)
    order('id ' + direction)
  end
end
