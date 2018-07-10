module SaleReport
    require 'dates_helper'
    include DatesHelper
    
    # reported staff list
    # format:
    # current_staff => [reporting_ids]
    def staffs 
      {
        :gavin => [10],
        :mat => [54, 50, 5],
        :amy => [55, 44, 35]
      }
    end

    # generate and return all required data upon a request 
    def genereate_sale_report_data staffs
      to_date = Date.today

      quarterly = "quarterly"
      num_quarter = 4         # max 4

      monthly = "monthly"
      num_month = 6           # max 12

      weekly = "weekly"
      num_weeks = 14          # max 52

      q_data = get_periodic_sales quarterly, num_quarter, to_date, staffs
      m_data = get_periodic_sales monthly, num_month, to_date, staffs
      w_data = get_periodic_sales weekly, num_weeks, to_date, staffs

      q_lines = get_projection_data quarterly, num_quarter, to_date, staffs, :count_product_lines
      q_qty = get_projection_data quarterly, num_quarter, to_date, staffs, :sum_qty
      q_avg_luc = get_projection_data quarterly, num_quarter, to_date, staffs, :avg_luc

      projecting_data = get_projecting_data staffs

      [q_data, m_data, w_data, q_lines, q_qty, q_avg_luc, projecting_data]
    end

    def get_projection_data frequency, freq_count, to_date, staffs, agg_func
      dates = periods_from_end_date(freq_count, to_date, frequency)

      # returns a hash like {week_num/month_num => [start_date, to_date]}
      # i.e. { 20=>[Mon, 14 May 2018, Mon, 21 May 2018] }
      dates_paired = pair_dates(dates, frequency)

      # should return - group_by_week_created for weekly period
      #               - group_by_month_created for monthly period
      #               - group_by_quarter_created for quarterly period
      group_by_function = (period_date_functions(frequency)[2] + "_and_customer_id").to_sym

      periodic_sum_orders = Order.date_filter(dates[0], dates[-1])
                              .valid_order
                              .customer_staffs_filter(staffs)
                              .order_by_staff_customer
                              .group_by_quarter_created_and_customer_id
                              .send(agg_func)
      [dates_paired, periodic_sum_orders]
    end

    # get projecting data of each sale rep from projections table 
    # return a hash of customers with respective projection data
    # ie. {
    #       "Alma Restaurant"=>[9, 240, 24.0, 5760.0], 
    #       "Arcadia Gastronomique"=>[1, 24, 18.0, 432.0]
    #     }
    def get_projecting_data staffs
      data = Projection.projecting_data staffs
      h_data = {}
      data.map{
        |key| h_data[key.customer_name] = [
                                            key.q_lines, 
                                            key.q_bottles, 
                                            key.q_avgluc, 
                                            key.q_bottles * key.q_avgluc
                                          ]
      }
      h_data
    end


    # this function return weekly sale figures of staffs 
    # in a number of week to a specified date
    # params: 
    # => freq_count : a number of week to be reported, take an int
    # => to_date    : report up to a specified date, accept a date
    # => staffs     : report sale figures of a group of staffs, accept an array
    # 
    # return an array of hash
    # => date_paired        : return a set of date pairs of each week
    #                       : ie.{ 20=>[Mon, 14 May 2018, Mon, 21 May 2018] } 
    # => periodic_sum_orders  : return a set of sale figures of each customer
    #                       : of each reporting week.
    #                       : ie. {['Canvas Bar', 12] => 463.2}
    def get_periodic_sales frequency, freq_count, to_date, staffs
      # frequency = "weekly"

      # periods_from_end_date is defined in Dates Helper
      # returns an array of all dates - sorted
      # For example freq_count = 3, to_date = 20th oct and "monthly" as period_type returns
      # {
      #   23=>[Mon, 04 Jun 2018, Mon, 11 Jun 2018], 
      #   24=>[Mon, 11 Jun 2018, Mon, 18 Jun 2018], 
      #   25=>[Mon, 18 Jun 2018, Wed, 20 Jun 2018]
      # }
      # 20th Oct is the last date in the array and not 19th oct because
      # we want to calculate orders including 19th Oct
      dates = periods_from_end_date(freq_count, to_date, frequency)

      # returns a hash like {week_num/month_num => [start_date, to_date]}
      # i.e. { 20=>[Mon, 14 May 2018, Mon, 21 May 2018] }
      dates_paired = pair_dates(dates, frequency)

      # should return - group_by_week_created for weekly period
      #               - group_by_month_created for monthly period
      #               - group_by_quarter_created for quarterly period
      group_by_function = (period_date_functions(frequency)[2] + "_and_customer_id").to_sym

      periodic_sum_orders = Order.date_filter(dates[0], dates[-1])
                              .valid_order
                              .customer_staffs_filter(staffs)
                              .order_by_staff_customer
                              .send(group_by_function)
                              .sum_total

      [dates_paired, periodic_sum_orders]
    end
end