class BigcommerceOrderProduct < ActiveRecord::Base
  def insert(order_id, order_history)

    order_product_api = Bigcommerce::OrderProduct
    order_products = order_product_api.all(order_id)

    if order_products.blank?
      return
    end

    # New Order Table
    order = Order.where("source = 'bigcommerce' AND source_id = ?", order_id).first
    # Delete Products that no long exist in new order
    OrderProduct.where('order_id = ? AND product_id NOT IN (?)', order.id, order_products.map(&:product_id)).map(&:delete_product) unless order_history.nil?

    order_products.each do |op|
      time = Time.now.to_s(:db)
        inserts_products = "('#{op.order_id}', '#{op.product_id}', '#{op.order_address_id}',\
        '#{op.quantity}', '#{op.quantity_shipped}', '#{op.base_price}', '#{op.price_ex_tax}',\
        '#{op.price_inc_tax}', '#{op.price_tax}', '#{time}', '#{time}')"

        sql_products = "INSERT INTO order_products (order_id, product_id, order_shipping_id, qty,\
        qty_shipped, base_price, price_ex_tax, price_inc_tax, price_tax,\
      created_at, updated_at) VALUES #{inserts_products}"

      ActiveRecord::Base.connection.execute(sql_products)

      if order_history.nil?
        OrderProduct.new.import_from_bigcommerce(order, op, order_history)
      else
        order_product = OrderProduct.where('order_id = ? AND product_id = ?', order.id, op.product_id)
        if order_product.count > 0
          order_product.first.import_from_bigcommerce(order, op, order_history)
        else
          OrderProduct.new.import_from_bigcommerce(order, op, nil)
        end
      end

    end
  end

  def delete(order_id)
    delete_order_product = "DELETE FROM order_products WHERE order_id = '#{order_id}'"
      ActiveRecord::Base.connection.execute(delete_order_product)
  end
end
