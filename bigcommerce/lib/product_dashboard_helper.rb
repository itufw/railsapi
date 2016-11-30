module ProductDashboardHelper

	def product_ids_for_hash(qty_hash)
        product_ids_a = []
        qty_hash.keys.each { |date_id_pair| product_ids_a.push(date_id_pair[0])}
        return product_ids_a
    end

end