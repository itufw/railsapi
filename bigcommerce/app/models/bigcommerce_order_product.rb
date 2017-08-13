class BigcommerceOrderProduct < ActiveRecord::Base
  def insert(order_id)

    order_product_api = Bigcommerce::OrderProduct
    order_products = order_product_api.all(order_id)

    if order_products.blank?
      return
    end

    # New Order Table
    order = BigcommerceOrder.find(order_id)
    # Delete Products that no long exist in new order
    BigcommerceOrderProduct.where('order_id = ? AND product_id NOT IN (?)', order.id, order_products.map(&:product_id)).map(&:delete_product)

    order_products.each do |op|
      time = Time.now.to_s(:db)
        inserts_products = "('#{op.order_id}', '#{op.product_id}', '#{op.order_address_id}',\
        '#{op.quantity}', '#{op.quantity_shipped}', '#{op.base_price}', '#{op.price_ex_tax}',\
        '#{op.price_inc_tax}', '#{op.price_tax}', '#{time}', '#{time}')"

        sql_products = "INSERT INTO bigcommerce_order_products (order_id, product_id, order_shipping_id, qty,\
        qty_shipped, base_price, price_ex_tax, price_inc_tax, price_tax,\
      created_at, updated_at) VALUES #{inserts_products}"

      ActiveRecord::Base.connection.execute(sql_products)

    end
  end

  def delete(order_id)
    delete_order_product = "DELETE FROM bigcommerce_order_products WHERE order_id = '#{order_id}'"
      ActiveRecord::Base.connection.execute(delete_order_product)
  end
end