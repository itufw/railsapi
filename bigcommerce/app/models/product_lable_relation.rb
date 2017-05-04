# connect lable and products
class ProductLableRelation < ActiveRecord::Base
  belongs_to :product_lable
  belongs_to :product

  def update_lables(product_ids, lable)
    relations = ProductLableRelation.lable_filter(lable)
    product_ids.each do |product|
      next if relations.map(&:product_id).include?product
      ProductLableRelation.new do |p|
        p.product_id = product
        p.product_lable_id = lable
        p.save
      end
    end
  end

  def destroy_lables(product_ids, lable)
    relations = ProductLableRelation.lable_filter(lable).product_filter_out(product_ids)
    relations.each do |relation|
      relation.destroy
    end
  end

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
