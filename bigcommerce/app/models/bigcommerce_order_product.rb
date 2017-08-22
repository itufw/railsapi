class BigcommerceOrderProduct < ActiveRecord::Base
  def insert(order_id)

    order_product_api = Bigcommerce::OrderProduct
    order_products = order_product_api.all(order_id)

    if order_products.blank?
      return
    end

    order = Order.where('source = ? AND source_id = ?', 'bigcommerce', order_id).first
    new_op = order.order_products.select{|x| x} unless order.nil?

    order_products.each do |op|
      time = Time.now.to_s(:db)
        inserts_products = "('#{op.order_id}', '#{op.product_id}', '#{op.order_address_id}',\
        '#{op.quantity}', '#{op.quantity_shipped}', '#{op.base_price}', '#{op.price_ex_tax}',\
        '#{op.price_inc_tax}', '#{op.price_tax}', '#{time}', '#{time}')"

        sql_products = "INSERT INTO bigcommerce_order_products (order_id, product_id, order_shipping_id, qty,\
        qty_shipped, base_price, price_ex_tax, price_inc_tax, price_tax,\
      created_at, updated_at) VALUES #{inserts_products}"

      ActiveRecord::Base.connection.execute(sql_products)

      unless order.nil?
        op_main = new_op.select {|x| x.product_id == op.product_id}.first
        op_main.import_from_bigcommerce(order, op) unless op_main.nil?
        OrderProduct.new.import_from_bigcommerce(order, op) if op_main.nil?
        new_op = new_op.reject{|x| x == op_main }
      end
    end
  end

  def delete(order_id)
    delete_order_product = "DELETE FROM bigcommerce_order_products WHERE order_id = '#{order_id}'"
      ActiveRecord::Base.connection.execute(delete_order_product)

    order = Order.where('source = ? AND source_id = ?', 'bigcommerce', order_id).first
    order.order_products.map(&:delete_product) unless order.nil?
  end
end
