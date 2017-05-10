# connect lable and products
class ProductLableRelation < ActiveRecord::Base
  belongs_to :product_lable
  belongs_to :product


  def self.lable_filter(lable)
    where('product_lable_relations.product_lable_id = ?', lable)
  end

  def self.product_filter(product_ids)
    where('product_lable_relations.product_id IN (?)', product_ids)
  end

  def self.product_filter_out(product_ids)
    return all if product_ids.blank?
    where('product_lable_relations.product_id NOT IN (?)', product_ids)
  end
end
