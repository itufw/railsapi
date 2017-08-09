module StatusHelper
    def get_id_and_name(params)
        status_id = params[:status_id]
        status_name = params[:status_name]
        if status_id.nil?
            status_id = 11
            status_name = 'Created'
        end
        [status_id, status_name]
    end

    def staff_filter(params)
        staff_id, staff = staff_params_filter(params)
        [staff_id, staff]
    end

    def products(params, staff_id, status_id)
        producer_country, product_sub_type, products, search_text = product_filter(params)
        product_ids = products.pluck('id')

        [product_ids, producer_country, product_sub_type, search_text]
    end

    def orders(params, product_ids, staff_id, status_id)
        case params[:transform_column]
        when 'product_no_vintage_id'
            product_ids = Product.products_with_same_no_vintage_id(product_ids).map { |x| x[:id] }
        when 'product_no_ws_id'
            product_ids = Product.products_with_same_no_ws_id(product_ids).map { |x| x[:id] }
        end
        search_text = params[:search]
        customer_ids = (search_text.nil?) ? [] : Customer.search_for(search_text).pluck("id")
        # orders = Order.date_filter(params[:start_date], params[:end_date]).customer_filter(customer_ids).staff_filter(staff_id).status_filter(status_id)


        orders = Order.include_all.status_filter(status_id).staff_filter(staff_id).product_customer_filter(product_ids, customer_ids)
        # {order_id => date }
        last_order_date = last_order_date_customer(orders, product_ids)

        if product_ids.empty?
          # extra product ids for customer search
          order_product_ids = OrderProduct.order_filter(orders.pluck("id")).pluck("product_id")
          product_ids.push(*order_product_ids)
        end

        # in lib->sales_controller_helper
        #{product_id => [number_of_orders, status_qty, orders_dollar_sum, product_name, product_stock]}
        products = (product_ids.empty?)? [] : products_for_status(status_id, staff_id, product_ids)
        order_function, direction = sort_order(params, :order_by_id, 'DESC')
        per_page = params[:per_page] || Order.per_page
        orders = orders.include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
        [per_page, orders, products, last_order_date]
    end

    # search for the last order date
    # if search_text is not null, find the relevant order date
    def last_order_date_customer(orders, product_ids)
      last_order_date = {}
      return last_order_date if orders.nil?

      product_orders = Order.product_filter(product_ids)
      orders.each do |order|
        last_order_date[order.id] = product_orders.customer_filter([order.customer_id]).order_by_date_created('DESC').map{|x| x[:date_created]}[1]
      end
      last_order_date
    end

    def print_shipping_sheet(selected_orders)
      orders = Order.where(id: selected_orders)
      pdf = CombinePDF.new

      orders.each do |order|
        customer = Customer.find(order.customer_id)
        order_invoice = WickedPdf.new.pdf_from_string(
          render_to_string(
              :template => 'pdf/order_invoice.pdf',
              :locals => {order: order, customer: customer}
              )
          )
        pdf << CombinePDF.parse(order_invoice)
      end
      picking_sheet = WickedPdf.new.pdf_from_string(
        render_to_string(
            template: 'pdf/picking_sheet.pdf',
            locals: {order_products: OrderProduct.where(order_id: selected_orders) }
            )
        )

      pdf << CombinePDF.parse(picking_sheet)
      pdf
    end
end
