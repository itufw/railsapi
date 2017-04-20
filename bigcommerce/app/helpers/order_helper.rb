module OrderHelper
    def orders_page_title(staff_nickname, start_date, end_date)
        if start_date.nil? || start_date.blank?
            'Orders'
        else
            if staff_nickname.nil?
                "Orders from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
            else
                "Orders for #{staff_nickname} from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
            end
        end
      end

    def product_qty(product_ids, order_id)
        Order.order_filter_(order_id).order_product_filter(product_ids).sum_order_product_qty
      end

    def invoice_status(xero_invoice)
        XeroInvoice.paid(xero_invoice) || XeroInvoice.unpaid(xero_invoice) \
        || XeroInvoice.partially_paid(xero_invoice) || [' ', ' ']
   end

    def order_controller_filter(params, _rights_col)
        staff, status, orders, search_text, order_id = order_filter(params, session[:user_id], 'product_rights')
        [staff, status, orders, search_text, order_id]
      end

    def order_display_(params, orders)
        order_function, direction = sort_order(params, :order_by_id, 'DESC')
        per_page = params[:per_page] || Order.per_page
        orders = orders.include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
        [per_page, orders]
      end
end
