require 'sales_controller_helper.rb'
require 'dates_helper.rb'
require 'display_helper.rb'
require 'models_filter.rb'

class SalesController < ApplicationController

  before_action :confirm_logged_in

  include SalesControllerHelper
  include DatesHelper
  include DisplayHelper
  include ModelsFilter

  # Displays this week's and last week's total order sales
  # Also displays total order sales for this week divided by staff
  def sales_dashboard
    # Date selected by user , default is today's date
    date_given = return_date_given(params)

    @dates_this_week = this_week(date_given)
    @dates_last_week = last_week(@dates_this_week[0])

    sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])

      # returns a hashmap like { date => order_totals }
    @sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created, sum_function, nil)
    @sum_last_week = sum_orders(@dates_last_week[0], @dates_last_week[-1], :group_by_date_created, sum_function, nil)

    @dates_paired_this_week = make_daily_dates_map(@dates_this_week)
    @dates_paired_last_week = make_daily_dates_map(@dates_last_week)

    # returns a hashmap like { [staff_id, date] => order_totals }

    staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])

    @staff_sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created_and_staff_id, sum_function, staff_id)
    #@staff_nicknames = Staff.active_sales_staff.nickname.to_h
    @staff_sum_this_week
  end

  def sales_dashboard_detailed
    @end_date = return_end_date(return_date_given(params))
    if params[:num_period]
      @num_periods = params[:num_period].to_i
    else
      @num_periods = 13
    end
    sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])
    @selected_period, @period_types = define_period_types(params)

    # periods_from_end_date is defined in Dates Helper
    # returns an array of all dates - sorted
    # For example num_periods = 3, end_date = 5th oct and "monthly" as period_type returns
    # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
    # 6th Oct is the last date in the array and not 5th oct because
    # we want to calculate orders including 5th Oct, for that we need to give the next day
    dates = periods_from_end_date(@num_periods, @end_date, @selected_period)
     # returns a hash like {[start_date, end_date] => week_num/month_num}
    @dates_paired = pair_dates(dates, @selected_period)

    @periods = (3..15).to_a

    # order_sum_param takes into account what the user wants to calculate - Bottles or Order Totals
    # order_sum_param is defined in Sales Controller Helper
    # Sum function returns :sum_qty or :sum_total
    # These functions are defined in the Order model
    sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])

    # sum_orders returns a hash like {date/week_num/month_num => sum} depending on the date_type
    # defined in Sales Controller Helper

    # date_type returns group_by_week_created or group_by_month_created
    date_function = period_date_functions(@selected_period)[2]
    @sums_by_periods = sum_orders(dates[0], dates[-1], date_function.to_sym, sum_function, nil)

    staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])
    @staff_sum_by_periods = sum_orders(dates[0], dates[-1], (date_function + "_and_staff_id").to_sym, sum_function, staff_id)

  end

      def product_sales(params)
        @end_date = return_end_date(return_date_given(params))
        if params[:num_period]
          @num_periods = params[:num_period].to_i
        else
          @num_periods = 13
        end
        @periods = (3..15).to_a
        # This returns
        @selected_period, @period_types = define_period_types(params)

        sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])
        if params[:sum_param].nil?
            sum_function, @param_val = :sum_qty,  "Bottles"
        end
        # periods_from_end_date is defined in Dates Helper
        # returns an array of all dates - sorted
        # For example num_periods = 3, end_date = 5th oct and "monthly" as period_type returns
        # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
        # 6th Oct is the last date in the array and not 5th oct because
        # we want to calculate orders including 5th Oct, for that we need to give the next day
        dates = periods_from_end_date(@num_periods, @end_date, @selected_period)
        # returns a hash like {week_num/month_num => [start_date, end_date]}
        @dates_paired = pair_dates(dates, @selected_period)

        date_function = (period_date_functions(@selected_period)[2] + "_and_product_id").to_sym


        staff_id, @staff = staff_params_filter(params)
        cust_style_id, @cust_style = collection_param_filter(params, :cust_style, CustStyle)

        @qty_hash = Order.valid_order.date_filter(dates[0], dates[-1]).staff_filter(staff_id).\
        cust_style_filter(cust_style_id).send(date_function).send(sum_function)

        @product_ids_a = product_ids_for_hash(@qty_hash)
    end

    def products_filter(products_unfiltered_a, params)
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @producer, @producer_region, @product_type, @producer_country,\
    @product_sub_type, products_filtered, @search_text, @product_sub_types, @producers,\
    @producer_regions = \
    product_dashboard_param_filter(params)

    @products = Product.filter_by_ids_nil_allowed(products_unfiltered_a & products_filtered.pluck("id")).send(order_function, direction)
    @pending_stock_h = Product.pending_stock('products.id')
    end

    def product_dashboard
        products_unfiltered = product_sales(params)
        products_filter(products_unfiltered, params)
    end

    def product_ids_for_hash(qty_hash)
        product_ids_a = []
        qty_hash.keys.each { |date_id_pair| product_ids_a.push(date_id_pair[0])}
        return product_ids_a
    end

end
