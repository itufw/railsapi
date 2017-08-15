require 'models_filter.rb'
require 'sales_controller_helper.rb'
require 'dates_helper.rb'
require 'time_period_stats.rb'
require 'status_helper.rb'
require 'fastway.rb'

class StatusController < ApplicationController
  before_action :confirm_logged_in

  include ModelsFilter
  include SalesControllerHelper
  include DatesHelper
  include TimePeriodStats
  include StatusHelper

  def pending
    @status_id, @status_name = get_id_and_name(params)
    staff_id, @staff = staff_filter(params)
    product_filtered_ids, @producer_country, @product_sub_type, @search_text = \
      products(params, staff_id, @status_id)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, product_filtered_ids, staff_id, @status_id)
  end

  # DON'T Use
  def order_status
    customer_ids = (params[:search].nil?) ? [] : Customer.search_for(params[:search]).pluck("id")
    per_page = params[:per_page] || Order.per_page
    order_function, direction = sort_order(params, :order_by_id, 'DESC')

    @orders = Order.where('status_id != 10').customer_filter(customer_ids)\
      .send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end

  def status_check
    @status_name = params[:status_name]
    status_ids = Status.where("alt_name LIKE '%#{@status_name}%'").map(&:id)

    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    per_page = params[:per_page] || Order.per_page
    @orders = Order.statuses_filter(status_ids).send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end

  def status_update
    selected_orders = params[:selected_orders] || []
    selected_orders = selected_orders.first.split unless selected_orders.blank? || selected_orders.count > 1

    # Print Shipping List
    if "Paperwork" == params[:commit] && !selected_orders.blank?
      # Print Picking Sheet
      # Due to Rails redirect conflicts
      pdf = print_shipping_sheet(selected_orders)
      send_data pdf.to_pdf, filename: "picking_sheet_#{session[:username]}_#{Date.today.to_s}.pdf" and return
    end

    # Group Update
    if ['Picked', 'Ready', 'Shipped'].include? params[:commit]
      status_id = 8 if params[:commit] == 'Picked'
      status_id = 9 if params[:commit] == 'Ready'
      status_id = 2 if params[:commit] == 'Shipped'
      Order.where(id: selected_orders).update_all(status_id: status_id)
      redirect_to controller: 'status', action: 'order_status' and return
    end

    # Individual Update
    # Skip current record
    if "Skip" == params[:commit]
    elsif "Approve" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 3}))
    elsif "Hold-Stock" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 20}))
    elsif "Hold-Price" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 7}))
    elsif "Hold-Other" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 13}))
    elsif "Create Label" == params[:commit]
      # Create Fastway Label & Create tracking information for orders
      # IF order_params[:courier_status_id] == 3 -> Create FASTWAY Label
      # Else: just record the label number
      if order_params[:courier_status_id] == '3'
        order = Order.find(params[:order_id])
        order.update_attributes(order_params.reject{|key, value| key == 'courier_status_id' })
        result = Fastway.new.add_consignment(order, params['dozen'].to_i, params['half-dozen'].to_i)
        begin
          order.update_attributes(order_params.merge({'track_number': result['result']['LabelNumbers'].join(';')}))
          flash[:success] = "Label Printed"
          order.update_attributes({courier_status_id: 4, status_id: 2, date_shipped: Date.today.to_s(:db)})
        rescue
          flash[:error] = 'Fail to connect Fastway, Check the Shipping Address'
          flash[:error] = result['error'] unless result.nil? || result[:error].nil?
          selected_orders.unshift(params[:order_id])
          redirect_to controller: 'order', action: 'order_confirmation', order_id: selected_orders.first, selected_orders: selected_orders, status_id: params[:status_id] and return
        end
        # create label with fastway
      else
        Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 2, date_shipped: Date.today.to_s(:db)}))
      end
    elsif "Delivered" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 12}))
    elsif "Problem" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params)
    elsif "Complete" == params[:commit]
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 10}))
    elsif !params[:order].nil?
      status = Status.find(params[:order][:status_id])
      order = Order.find(params[:order][:id])
      # Approved, Partially Paid, Unpaid, Paid, Hold-Accounts
      account_status = params[:order][:account_status]
      if account_status == "Hold-Account" && status.in_transit == 1
        flash[:error] = "Account Hold for Order#" + order.id.to_s
      else
        order.assign_attributes(params[:order].permit(:status_id, :account_status, :courier_status_id))
        order.save
      end
    end

    if selected_orders.blank?
      redirect_to controller: 'order', action: 'all' and return
    else
      redirect_to controller: 'order', action: 'order_confirmation', order_id: selected_orders.first, selected_orders: selected_orders, status_id: params[:status_id] and return
    end
  end

  def summary_with_product
    @status_id, @status_name = get_id_and_name(params)
    @product_id = params[:product_id]
    @product_name = params[:product_name]
    @num_orders = params[:num_orders]
    @qty = params[:qty]
    @status_qty = params[:status_qty]
    @total = params[:total]

    staff_id, @staff = staff_filter(params)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, @product_id, staff_id, @status_id)
    @overall_stats = overall_stats_(params)
  end

  def overall_stats_(params)
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.order_product_filter(%s).status_filter(%s)' % \
       [@product_id, @status_id], :sum_order_product_qty, @selected_period, nil)
  end

  def fetch_last_products
    orders = Order.where(customer_id: params[:customer_id]).order('updated_at DESC')
    @last_order = orders.first
    order_ids = orders.map(&:id)
    @ops = OrderProduct.where("order_id IN (?) AND created_at > ?", order_ids, (Date.today - 3.month).to_s(:db))
    respond_to do |format|
      format.js
    end
  end
end

private
  def order_params
    params.require(:order).permit(:id, :status_id, :courier_status_id,\
      :account_status, :address, :billing_address, :customer_notes,\
      :staff_notes, :delivery_instruction, :SpecialInstruction1, :SpecialInstruction2,\
      :SpecialInstruction3)
  end
