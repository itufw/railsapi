module OrderHelper

	def product_qty(product_ids, order_id)
    	return Order.order_filter_(order_id).product_filter(product_ids).sum_order_product_qty
  	end


end