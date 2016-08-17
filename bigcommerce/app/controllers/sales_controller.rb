 class SalesController < ApplicationController

  before_action :confirm_logged_in

    def view_sales_dashboard
        # Current and Last week sales summaries
        date_param = params[:selected_date]

        if !date_param.blank?
          date_given = date_param[:selected_date].to_date
          start_date = date_given
        else
          date_given = Date.today
          start_date = date_given.at_beginning_of_week
        end

        
        end_date = 6.days.since(start_date)
        @dates_this_week = (start_date..end_date).to_a
        sums_this_week = sum_orders(start_date, end_date)
        @result_this_week = get_daily_totals(@dates_this_week, sums_this_week)

        date_sum_staff_map = sum_orders_by_staff(start_date, end_date)
        @this_week_staff_totals = get_staff_totals(@dates_this_week, date_sum_staff_map)


        last_week_start_date = start_date - 7.days
        #last_week_start_date = seven_days_ago.at_beginning_of_week
        last_week_end_date = 6.days.since(last_week_start_date)
        @dates_last_week = (last_week_start_date..last_week_end_date).to_a
        sums_last_week = sum_orders(last_week_start_date, last_week_end_date)
        @result_last_week = get_daily_totals(@dates_last_week, sums_last_week)

    end

    def sum_orders(start_date, end_date)
        start_time = Time.parse(start_date.to_s)
        end_time = Time.parse(end_date.to_s)

        date_sum_map = Order.includes(:status).where('date_created >= ? and date_created < ? and statuses.valid_order = 1', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S")).references(:statuses).group('DATE(date_created)').sum('total_inc_tax')
        
        return date_sum_map

    end

    def sum_orders_by_staff(start_date, end_date)
        start_time = Time.parse(start_date.to_s)
        end_time = Time.parse(end_date.to_s)
        date_sum_staff_map = Order.includes(:customer, :status).where('orders.date_created >= ? and orders.date_created < ? and statuses.valid_order = 1', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S")).references(:statuses).group(['customers.staff_id', 'DATE(orders.date_created)']).references(:customers).sum('orders.total_inc_tax')
        return date_sum_staff_map
    end

    def get_daily_totals(dates, sums)
        result = []
        total = 0

        dates.each do |d|
            if sums.has_key? d
              day_sum = sums[d]
              total += day_sum
            else
              day_sum = 0
            end
            result.push(day_sum)
        end

        result.push(total)

        return result
    end

    def get_staff_totals(dates, date_sum_staff_map)

        staff_weekly_totals = []

        all_active_staffs = Staff.where('active = 1 and user_type LIKE "Sales%"')

        all_active_staffs.each do |as|

            staff_map_per_id = date_sum_staff_map.select { |key, value| key[0] == as.id }
            if staff_map_per_id.keys.count != 0
                 day_sum_map = Hash.new
                 staff_map_per_id.each {|k,v| day_sum_map[k[1]] = v}
                 sum_array = get_daily_totals(dates, day_sum_map)
            else
                 sum_array = [0,0,0,0,0,0,0]
            end

             weekly_each_staff_sums = []
             weekly_each_staff_sums.push(as.nickname)
             weekly_each_staff_sums.push(sum_array)
             weekly_each_staff_sums.push(as.id)

             staff_weekly_totals.push(weekly_each_staff_sums)

        end

        return staff_weekly_totals 

    end

    # def view_daily_orders_for_rep

    #     @staff_nickname = params[:staff]
    #     staff_id = params[:staff_id]

    #     @date = params[:date]

    #     start_time = Time.parse(@date.to_s)
    #     end_time = 1.day.since(start_time)

    #     @daily_orders_for_rep = Order.includes(:customer, :status).where('orders.date_created >= ? and orders.date_created < ? and customers.staff_id = ?', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), staff_id).references(:customers).order('orders.id DESC')

    #     @page_header = "Orders for Date : #{@date.to_date.strftime('%A  %d/%m/%y')} and Staff : #{@staff_nickname}"

    # end

    # def view_weekly_orders_for_rep

    #     @staff_nickname = params[:staff]
    #     staff_id = params[:staff_id]

    #     @date = params[:week_start_date]

    #     start_time = Time.parse(@date.to_s)
    #     end_time = 7.days.since(start_time)

    #     @daily_orders_for_rep = Order.includes(:customer, :status).where('orders.date_created >= ? and orders.date_created < ? and customers.staff_id = ?', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), staff_id).references(:customers).order('orders.id DESC')

    #     @page_header = "This Week's of Staff : #{@staff_nickname}"

    #     render "view_daily_orders_for_rep"

    # end

    # def view_overall_daily_orders

    #     @date = params[:date]

    #     start_time = Time.parse(@date.to_s)
    #     end_time = 1.day.since(start_time)

    #     @daily_orders = Order.includes([{:customer => :staff}, :status]).where('orders.date_created >= ? and orders.date_created < ?', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S")).order('id DESC')

    #     @page_header = "Orders for Date : #{@date.to_date.strftime('%A  %d/%m/%y')}"

    # end

    def view_orders_for_customer
      @customer_id = params[:customer_id]

      @orders = Order.includes([{:customer => :staff}, :status]).where('orders.customer_id = ?', @customer_id).order('id DESC')

      @customer_name = get_customer_name(@orders.first.customer)

      get_customer_stats(@customer_id)

      @page_header = "All Orders for #{@customer_name}"

    end

    def view_products_for_orderid
      
      @order_id = params[:order_id]

      @order = Order.includes([{:customer => :staff}, :status, {:order_products => :product}]).where('orders.id = ?', @order_id).first

      #@order_products = OrderProduct.includes(:product).where(order_id: @order_id)

      @page_header = "Order # #{@order_id}"

    end

    def view_orders_for_product_and_customer

        @customer_id = params[:customer_id]
        @customer_name = params[:customer_name]
        @product_id = params[:product_id]
        @product_name = params[:product_name]
  
        # need to take care - same products multiple times in same order
        @orders = Order.includes([{:customer => :staff}, :status, :order_products]).where('order_products.product_id = ? and orders.customer_id = ?', @product_id, @customer_id).order('orders.id DESC').references(:order_products)

        @time_periods = StaffTimePeriod.where('display = ?', 1)
        @average_time_specified = DefaultAveragePeriod.where(staff_id: 19).first
        @product_stats_sum = []
        @product_stats_avg = []

        @time_periods.each do |t|
            start_time = Time.parse(t.start_date.to_s)
            end_time = Time.parse(t.end_date.to_s)
            sum = Order.includes(:order_products, :status).where('orders.customer_id = ? and orders.date_created >= ? and orders.date_created <= ? and statuses.valid_order = 1 and order_products.product_id = ?', @customer_id, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), @product_id).references(:statuses, :order_products).sum('order_products.qty')
            num_days = (t.end_date.to_date - t.start_date.to_date).to_i
            avg = (sum.to_f/num_days)*(@average_time_specified.days.to_i)
            @product_stats_sum.push(sum)
            @product_stats_avg.push(avg)
        end

    end

    def view_orders_by_status

      @status_id = params[:status_id]
      @status_name = params[:status_name]

      if @status_id.nil?
        @status_id = 1
        @status_name = "Pending"
      end

      @all_statuses = Status.all

      @all_statuses = Status.all

      @staffs = active_sales_staff
      @countries = ProducerCountry.all
      @sub_types = ProductSubType.all

      if params.has_key?(:commit) && !params[:staff][:id].blank?
        staff_id = params[:staff][:id]
        @staff = Staff.where(id: staff_id).first
        @orders = Order.includes([{:customer => :staff}]).where('orders.status_id = ? and staffs.id = ?', @status_id, staff_id).references(:staffs).order('orders.id DESC')
      else
        @orders = Order.includes([{:customer => :staff}]).where('orders.status_id = ?', @status_id).order('id DESC')
      end




      # need to reduce these to 1
      num_orders = Order.includes(:order_products).where('orders.status_id = 1').group('order_products.product_id').count('order_products.order_id')
      product_qty = Order.includes(:order_products).where('orders.status_id = 1').group('order_products.product_id').sum('order_products.qty')
      order_totals = Order.includes(:order_products).where('orders.status_id = 1').group('order_products.product_id').sum('orders.total_inc_tax')

      merge_1 = num_orders.merge(product_qty) { |k, o, n| [o, n] }
      merge_2 = merge_1.merge(order_totals) { |k, o, n| o.push(n)}

      product_hash = Product.where(id: merge_2.keys).pluck("id,name").to_h

      #{id => [number_of_orders, product_qty_total, total_orders_sum, product_name]}
      product_map = merge_2.merge(product_hash) { |k, o, n| o.push(n)}
      @product_map_sorted = Hash[product_map.sort_by { |k,v| v[3] }]


      @page_header_products = "Products with Status: #{@status_name}"
      @page_header_orders = "Orders with Status: #{@status_name}"

    end



    # You come here after you click on a product's name on the Status page
    # Status page is the one with the slide bar between orders and products
    # this gives all the orders that the order count referred to in that table

    def view_orders_for_product_and_status
        product_id = params[:product_id]
        status_id = params[:status_id]
        status = params[:status_name]
        @status_name = status
        product_name = params[:product_name]

        @result = []

        orders = Order.includes(:order_products, :customer).where('orders.status_id = ? and order_products.product_id = ?', status_id, product_id).references(:order_products)

        orders.each do |o|
            rep_nickname = Staff.where('id = ?', o.customer.staff_id).first.nickname
            date_created = o.date_created.to_date
            cust_name = get_customer_name(o.customer)
            cust_id = o.customer_id
            prod_qty = o.order_products.first.qty
            order_qty = o.qty
            order_total = o.total_inc_tax

            @result.push([rep_nickname, date_created, o.id, cust_name, prod_qty, order_qty, order_total, cust_id])
        end

        @page_header = "Status: #{status}  ,    Product: #{product_name}"
    end

    def get_customer_stats(customer_id)

        @time_periods = StaffTimePeriod.where('display = ?', 1)

        #@default_average_periods = DefaultAveragePeriod.first

        @sum_per_time_period = []
        @avg_per_time_period = []

        average_time_specified = DefaultAveragePeriod.where(staff_id: 19).first
        @average_name = average_time_specified.name
        #@average_description = DefaultAveragePeriod.where(staff_id: 19).first.name

        @time_periods.each do |t|

            start_time = Time.parse(t.start_date.to_s)
            end_time = Time.parse(t.end_date.to_s)
            sum = Order.includes(:status).where('date_created >= ? and date_created <= ? and customer_id = ? and statuses.valid_order = 1', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), customer_id).references(:statuses).sum(:total_inc_tax)
            @sum_per_time_period.push(sum)

            num_days = (t.end_date - t.start_date).to_i
            avg = (sum.to_f/num_days)*(average_time_specified.days.to_i)
            @avg_per_time_period.push(avg)
        end

    end

    def view_product_stats_for_customer

        @customer_id = params[:customer_id]
        @customer_name = params[:customer_name]

        @time_periods = StaffTimePeriod.where('display = ?', 1)
        @product_stats = []
        
        # show a grid for all products

        @time_periods.each do |t|
            
            start_time = Time.parse(t.start_date.to_s)
            end_time = Time.parse(t.end_date.to_s)
            @product_stats.push(Order.includes(:order_products, :status).where('orders.customer_id = ? and orders.date_created >= ? and orders.date_created <= ? and statuses.valid_order = 1', @customer_id, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S")).references(:statuses).group('order_products.product_id').sum('order_products.qty'))
            
        end

        # We have an array of hashes
        # Each hash represents products ordered in 1 time period
        # Key - product id, Value - product qty
        product_ids = @product_stats.reduce(&:merge).keys

        product_id_name_map = Product.where(id: product_ids).pluck("id,name").to_h

        @product_id_name_map_sorted = Hash[product_id_name_map.sort_by { |k,v| v }]

    end

    def check_id_in_map(stats_array, id)

        values_for_one_time_periods = []

        stats_array.each do |s|
            # s - hash of valid ids - values
            if s.has_key? id
              values_for_one_time_periods.push(s[id])
            else
              values_for_one_time_periods.push(0)
            end
        end

        return values_for_one_time_periods
    end

    helper_method :check_id_in_map

    def view_customer_stats_for_product

        @staffs = active_sales_staff

        @product_id = params[:product_id]
        @product_name = params[:product_name]

        @time_periods = StaffTimePeriod.where('display = ?', 1)
        @customer_stats = []

        @time_periods.each do |t|
            start_time = Time.parse(t.start_date.to_s)
            end_time = Time.parse(t.end_date.to_s)
            @customer_stats.push(Order.includes(:order_products, :customer, :status).where('order_products.product_id = ? and orders.date_created >= ? and orders.date_created <= ? and statuses.valid_order = 1', @product_id, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S")).references(:order_products, :statuses).group('customers.id').sum('order_products.qty'))
        end

        customer_ids = @customer_stats.reduce(&:merge).keys

        if params.has_key?(:commit) && !params[:staff][:id].blank?
            staff_id = params[:staff][:id]
            @staff = Staff.where(id: staff_id).first
            customer_id_name_array = Customer.includes(:staff).where('customers.id IN (?) and staffs.id = ?', customer_ids, staff_id).references(:staffs).pluck("customers.id, customers.actual_name, customers.firstname, customers.lastname, staffs.nickname")
        else
            customer_id_name_array = Customer.includes(:staff).where(id: customer_ids).pluck("customers.id, customers.actual_name, customers.firstname, customers.lastname, staffs.nickname")
        end


        customer_id_name_map = Hash[customer_id_name_array.map {|id, actual_name, firstname, lastname, staff| [id, [customer_name(firstname, lastname, actual_name), staff]]}]

        @customer_id_name_map_sorted = Hash[customer_id_name_map.sort_by { |k,v| v[0] }]
   
        @page_header = "Customers who ordered Product : #{@product_name}"

    end

    def view_orders_for_product

        @product_id = params[:product_id]
        @product_name = params[:product_name]

        @orders = Order.includes([{:customer => :staff}, :status, :order_products]).where('order_products.product_id = ?', @product_id).order('orders.id DESC').references(:order_products)

        @time_periods = StaffTimePeriod.where('display = ?', 1)
        @average_time_specified = DefaultAveragePeriod.where(staff_id: 19).first
        @product_stats_sum = []
        @product_stats_avg = []

        @time_periods.each do |t|
            start_time = Time.parse(t.start_date.to_s)
            end_time = Time.parse(t.end_date.to_s)
            sum = Order.includes(:order_products, :status).where('orders.date_created >= ? and orders.date_created <= ? and statuses.valid_order = 1 and order_products.product_id = ?', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), @product_id).references(:statuses, :order_products).sum('order_products.qty')
            num_days = (t.end_date.to_date - t.start_date.to_date).to_i
            avg = (sum.to_f/num_days)*(@average_time_specified.days.to_i)
            @product_stats_sum.push(sum)
            @product_stats_avg.push(avg)
        end
    end


end
