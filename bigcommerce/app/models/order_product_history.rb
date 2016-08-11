class OrderProductHistory < ActiveRecord::Base
	belongs_to :order_history
	belongs_to :product

	belongs_to :order_shipping_history

	def insert(order_history_id, order_id)
		time = Time.now.to_s(:db)

		order_products = OrderProduct.where(order_id: order_id)

		order_products.each do |op|

			inserts = ""

			inserts =  "('#{order_history_id}', '#{op.order_id}', '#{op.product_id}', '#{op.order_shipping_id}',\
			'#{op.qty}', '#{op.qty_shipped}', '#{op.base_price}', '#{op.price_ex_tax}',\
			'#{op.price_inc_tax}', '#{op.price_tax}', '#{time}', '#{time}')"

			insert_order_product = "INSERT INTO order_product_histories (order_history_id, order_id, product_id,\
			order_shipping_id, qty, qty_shipped, base_price, price_ex_tax, price_inc_tax, price_tax,\
			created_at, updated_at) VALUES #{inserts}"
			
		    ActiveRecord::Base.connection.execute(insert_order_product)
		end

	end
end
