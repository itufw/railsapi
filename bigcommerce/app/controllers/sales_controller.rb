 class SalesController < ApplicationController

  before_action :confirm_logged_in

    # Weekly sales summaries
    def sales_dashboard
        # Date selected by user , default is today's date
        date_param = params[:selected_date]

    end

    def orders_for_selected_customer
      @customer_id = params[:customer_id]
      # Can I get Customer Name ?
      # give all the orders for a customer id
      @orders = Order.include_customer_staff_status.customer_filter(@customer_id).order_by_id
    end

    def order_details
      @order_id = params[:order_id]
      @order = Order.include_all.order_filter(@order_id)
    end

    # WHEN DO WE COME TO THIS PAGE ? - We click on Order ID - then click on any one of the products
    def orders_for_selected_product_and_selected_customer
        @customer_id = params[:customer_id]
        @customer_name = params[:customer_name]
        @product_id = params[:product_id]
        @product_name = params[:product_name]
  
        # need to take care - same products multiple times in same order
        @orders = Order.include_customer_staff_status.filter_order_products(@product_id, nil).customer_filter(@customer_id).order_by_id
        stats_for_timeperiods("Order.filter_order_products(%s, nil).customer_filter(%s)" % [@product_id, @customer_id], "".to_sym, :sum_order_product_qty)
    end

    def orders_for_selected_product
        @product_id = params[:product_id]
        @product_name = params[:product_name]
        @orders = Order.include_customer_staff_status.filter_order_products(@product_id, nil).order_by_id
    end

end
