class ProductNoWs < ActiveRecord::Base
	def self.filter_by_ids(ids_a)
		return where('id IN (?)', ids_a)
	end

	def self.order_by_name(direction)
		order('name ' + direction)
	end
end
