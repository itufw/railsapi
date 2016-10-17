module StockHelper

	def total_stock_product(product_id)
		product_no_vintage_id = Product.no_vintage_id(product_id)
		similar_products = Product.products_with_same_no_vintage_id(product_no_vintage_id)
		inventory_sum = 0
		similar_products.each {|p| inventory_sum += p.inventory}
		pending_stock_sum = (Product.pending_stock(similar_products.pluck("id"))).values.sum
		return pending_stock_sum + inventory_sum
	end
end