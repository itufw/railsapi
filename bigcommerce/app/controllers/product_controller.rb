# filter products based on paramaters
require 'models_filter.rb'

# provide stats for no vintage products, no ws products
require 'product_variations.rb'

# to calculate overall stats and top customers
require 'time_period_stats.rb'

# for calendar period types for overall stats - weekly, monthly, quarterly
require 'dates_helper.rb'
require 'product_helper'
require 'application_helper.rb'
class ProductController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true


  include ModelsFilter
  include ProductVariations
  include TimePeriodStats
  include DatesHelper
  include ProductHelper
  include ApplicationHelper

  # Displays all products
  def all
    params[:incompleted] = true if params[:commit] == 'Incomplete Product'
    filtered_products = filter(params)
    transform(params)

    # check the number of queries - make it faster
    @stock_h, @price_h, @pending_stock_h, @name_h = \
      transform_product_data(@transform_column, filtered_products)
    display_all(params)

    # product Helper
    product_selection(params[:selected_product]) unless params[:selected_product].nil? || session[:default_group].nil? || params[:commit]=='Update'
    @count_selected = StaffGroupItem.productNoWs(session[:default_group]).map(&:item_id) if @transform_column=="product_no_ws_id" && !session[:default_group].nil?
  end

  # Displays Overall Stats and Top Customers for Product
  def summary
    params[:direction] = params[:direction] || -1
    params[:order_col] = params[:order_col] || 'Last Quarter'

    params_for_one_product(params)
    transform(params)
    # total_stock is inventory in bigcommerce + pending stock
    get_total_stock(params)
    # WS + Retail + Pending stock
    @total_stock_no_ws = total_stock_no_ws(@transform_column, @product_id, @pending_stock, @total_stock)

    # either we want stats for a product_id
    # or for products based on a product_no_vintage_id
    # or based on a product_no_ws_id
    # this gives product_ids based on that transform_column
    product_ids = get_products_after_transformation(@transform_column, @product_id).pluck('id') || @product_id

    # form filter for top customers

    # i only need to check product rights on this page
    # So if product rights is 0, then restrict by staff
    # otherwise just do a normal param filter
    @staff, customers_filtered, @search_text, staff_id, @cust_style = \
      customer_filter(params, session[:user_id], 'product_rights')
    customers_filtered_ids = customers_filtered.pluck('id')
    # both overall stats and top customers change based on the customer filter

    # overall_stats has structure {time_period_name => [sum, average, supply]}
    @overall_stats = \
      overall(params, product_ids, customers_filtered_ids, @total_stock)

    # top customers
    top_customers(params, product_ids, customers_filtered_ids)
      
    # calculate the pending stock for each customer
    @customer_pendings, @customer_ids = \
      customer_pending_amount(product_ids, params, @customer_ids)

    # Include all relevant products to overwrite stock level
    @products = Product.filter_by_ids_nil_allowed(product_ids)
  end

  def allocate
    unless params[:selected_product].nil? || params[:selected_product].blank?
      params[:product_id] = params[:selected_product].delete_at(0)
      params[:product_name], params[:total_stock] = product_name_inventory_after_transform(params[:product_id], params[:transform_column])
      @selected_product = params[:selected_product]
    end

    params[:direction] = params[:direction] || -1
    params[:order_col] = params[:order_col] || 'Last Quarter'

    params_for_one_product(params)
    transform(params)
    # total_stock is inventory in bigcommerce + pending stock
    get_total_stock(params)
    # WS + Retail + Pending stock
    # Ignore Pending Stock -> the 0
    @total_stock_no_ws = total_stock_no_ws(@transform_column, @product_id, 0, @total_stock)

    # either we want stats for a product_id
    # or for products based on a product_no_vintage_id
    # or based on a product_no_ws_id
    # this gives product_ids based on that transform_column
    @products = get_products_after_transformation(@transform_column, @product_id)
    product_ids = @products.pluck('id') || @product_id

    # Collect the allocated_stocks
    @allocated_stock = allocated_stock(product_ids)

    # form filter for top customers

    # i only need to check product rights on this page
    # So if product rights is 0, then restrict by staff
    # otherwise just do a normal param filter
    @staff, customers_filtered, @search_text, staff_id, @cust_style = \
      customer_filter(params, session[:user_id], 'product_rights')
    customers_filtered_ids = customers_filtered.pluck('id')
    # both overall stats and top customers change based on the customer filter

    # top customers
    top_customers(params, product_ids, customers_filtered_ids)

    # calculate the pending stock for each customer
    @customer_pendings, @customer_ids = \
      customer_pending_amount(product_ids, params, @customer_ids)
  end

  def allocate_products
    if params[:commit]=='Skip'
      redirect_to controller: 'product', action: 'allocate', transform_column: params[:transform_column], selected_product: params[:selected_product].split() and return
    end
    # transform_column=product_no_ws_id&selected_product%5B%5D=861&selected_product%5B%5D=40&selected_product%5B%5D=1271


    # Revision Date Conveter
    # From {"(1i)"=>"2017", "(2i)"=>"10", "(3i)"=>"8"} to Date
    revision_date = Date.parse params[:revision_date].values().join('-')
    # Find the correct Product(s)
    # No WS marks or product itself
    products = get_products_after_transformation(params[:transform_column], params[:product_id])
    # the valid customer - allocation pair
    allocated = params[:customer].select{ |key, value| value.to_i > 0 }

    if allocated.values().map(&:to_i).sum > products.sum(:inventory)
      flash[:error] = "Not Enough Stock, Return to Product Page and Refresh!"
      redirect_to request.referrer and return
    elsif !user_full_right(session[:authority])
      flash[:error] = "User Right Limitated"
      redirect_to request.referrer and return
    elsif params[:transform_column]!="product_id" && products.select{|x| x.name.end_with?'WS'}.first.nil?
      flash[:error] = "Not Enough Stock, Return to Product Page and Refresh!"
      redirect_to request.referrer and return
    elsif allocated.values().map(&:to_i).sum > products.select{|x| x.name.end_with?'WS'}.sum(&:inventory)
      product = products.select{|x| x.name.end_with?'WS'}.first
      allocate_inventory(product.id, products.map(&:id))
    end

    product_id = (params[:transform_column]!="product_id")? products.select{|x| x.name.end_with?'WS'}.first.id : params[:product_id]

    if 'Bulk Allocate'.eql?params[:commit]
      # Bulk Allocated
      # Product id IS WS Product ID
      Customer.where(id: allocated.keys()).map{|x| x.allocate_products(product_id, allocated[x.id.to_s].to_i, revision_date, session[:user_id]) }
    end

    if params[:commit]=='Allocate and Next'
      redirect_to controller: 'product', action: 'allocate', transform_column: params[:transform_column], selected_product: params[:selected_product].split() and return
    end

    redirect_to action: 'summary', pending_stock: allocated.values().map(&:to_i).sum, transform_column: params[:transform_column], product_name: params[:product_name], product_id: params[:product_id], total_stock: products.sum(:inventory)
  end

  def overall(params, product_ids, customers_filtered_ids, total_stock)
    # period type for overall stats - monthly or weekly
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.order_product_filter(%s).customer_filter(%s).valid_order' % \
      [product_ids, customers_filtered_ids], :sum_order_product_qty, @selected_period, total_stock)
  end

  def top_customers(params, product_ids, customers_filtered_ids)
    # result_h has the form {time_period_name => {customer_id => stock_bought}}
    # and it is sorted according to order_col and direction

    # the following commented statement causes coincident correctness, therefore,
    # they are disabled and replaced. Though, the update will further be investigated
    # to ensure it produces correct and desirable result.
    # @top_customers_timeperiod_h, @customer_ids, @time_periods, already_sorted = top_objects(\
      # 'Order.order_product_filter(%s).customer_filter(%s).valid_order' % \
        # [product_ids, customers_filtered_ids], :group_by_customerid, :sum_order_product_qty,\
    #   params[:order_col], params[:direction]
    # )
    @top_customers_timeperiod_h, @customer_ids, @time_periods, already_sorted = top_objects(
      'Order.order_product_filter(%s).customer_filter(%s).valid_and_allocated_orders' %
        [product_ids, customers_filtered_ids], 
      :group_by_customerid, 
      :sum_order_product_qty,
      params[:order_col], 
      params[:direction]
    )

    if already_sorted
      @top_customers = get_id_activerecord_h(Customer.include_all.filter_by_ids(@customer_ids))
    else
      default_customer_sort_order(params)
      @top_customers = get_id_activerecord_h(Customer.include_all.filter_by_ids(@customer_ids).send(@order_function, @direction))
      @customer_ids = @top_customers.keys
    end
  end

  def params_for_one_product(params)
    @product_id = params[:product_id]
    @product_name = params[:product_name]
  end

  def filter(params)
    @producer_country, @product_sub_type, products, @search_text = product_filter(params)
    products
  end

  def transform(params)
    @transform_column = params[:transform_column] || 'product_no_vintage_id'
    @checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)
  end

  def display_all(params)
    @per_page = params[:per_page] || Product.per_page
    # order_function, direction = sort_order(params, 'order_by_name', 'ASC')
    sort_map = { '0' => @name_h, '1' => @price_h, '2' => @stock_h }
    needs_to_be_sorted_h = sort_map[params[:order_col]] || @name_h

    if params[:direction] == '-1'
      # hash that needs to be sorted
      sorted_hash = needs_to_be_sorted_h.sort_by { |_id, val| -val }.to_h
    else
      sorted_hash = needs_to_be_sorted_h.sort_by { |_id, val| val }.to_h
    end

    @product_ids = sorted_hash.keys.paginate(per_page: @per_page, page: params[:page])
  end

  def default_customer_sort_order(params)
    @order_function, @direction = sort_order(params, :order_by_name, 'ASC')
  end

  def get_id_activerecord_h(customers)
    id_activerecord_h = {}
    return id_activerecord_h if customers.blank?
    customers.map { |c| id_activerecord_h[c.id] = c }
    id_activerecord_h
  end

  def get_total_stock(params)
    @total_stock = params[:total_stock].to_i
    @pending_stock = params[:pending_stock].to_i
  end

  def edit
    @product = Product.find(params[:product_id])
  end

  def update
    # Product Update
    # Location Updated
    if !params[:location_update].nil?
      unless params[:commit]=='Skip'
        params[:products].each do |id, location|
          ProductNoWs.find(id).update_attributes(location.permit(:row, :column, :area))
        end
        flash[:success] = 'Location Updated'
      end
      redirect_to action: 'location' and return

    # IN Product Detail -> assign Country / Name
    elsif params[:warehouse_examining].nil?
      if params[:new_product]=='1' && (product_params[:name_no_vintage].nil? || product_params[:name_no_ws].nil?)
        flash[:error] = 'Incorrect!'
        redirect_to :back and return
      elsif params[:new_product]=='1'
        product_no_ws = ProductNoWs.where("name LIKE ? ", '%' + product_params[:name_no_ws].to_s + '%').first
        if product_no_ws.nil?
          product_no_ws = ProductNoWs.new({name: product_params[:name_no_ws], product_no_vintage_id: product_params[:product_no_vintage_id]})
          product_no_ws.save
        end
      end

      product = Product.find(params[:product][:id])
      product.assign_attributes(product_params)
      product.product_no_ws_id = product_no_ws.id unless product_no_ws.nil?
      product.producer_country_id = product.producer.producer_country_id unless product.producer.nil?
      product.name_no_vintage = product.product_no_vintage.name unless product.product_no_vintage.nil?
      product.save

      redirect_to action: 'summary', product_id: product.id, product_name: product.name, transform_column: 'product_id', total_stock: product.inventory, pending_stock: product.inventory and return

    # Warehouse Counting
    else
      pending_products = params[:pending_products].split()
      later_count = params[:later].split()
      later_count.append(warehouse_params[:product_no_ws_id]) unless params[:latter_count].nil?

      if params[:commit]=='Save'
        if WarehouseExamining.duplicated(warehouse_params[:product_no_ws_id]).blank?
          warehouse = WarehouseExamining.new()
        else
          warehouse = WarehouseExamining.duplicated(warehouse_params[:product_no_ws_id]).first
        end
        warehouse.count_size = params[:warehouse_examining][:product][:case_size]
        warehouse.update_attributes(warehouse_params.merge({count_staff_id: session[:user_id], count_date: Time.now().to_s(:db)}))

        ProductNoWs.find(params[:warehouse_examining][:product][:id])
         .update(params[:warehouse_examining][:product].permit(:row, :column, :area, :case_size))
      end

      # if no more pending products to be Counted
      # return to dashboard
      if pending_products.blank? && later_count.blank?
        flash[:success] = 'Counted all selected product, please review it!'
        redirect_to controller: 'sales', action: 'sales_dashboard' and return
      elsif pending_products.blank?
        pending_products = later_count
        later_count = []
      end
      redirect_to action: 'warehouse', pending_products: pending_products, later_count: later_count and return
    end
  end

  def warehouse
    # Assign new group
    session[:default_group] = params[:selected_group] if params[:selected_group]

    if !session[:default_group] || StaffGroupItem.productNoWs(session[:default_group]).blank?
      @group_list = StaffGroup.staff_groups(session[:user_id])
    else
      @product_list = (params[:pending_products].nil?) ? StaffGroupItem.productNoWs(session[:default_group]).map(&:item_id) : params[:pending_products]
      @product_list = ProductNoWs.where(id: @product_list).order(:column).map(&:id)
      @product = ProductNoWs.find(@product_list.first)
      @product_list = @product_list.reject{|x| x.to_s==@product.id.to_s}

      @waitting_list = params[:later_count]

      @products = @product.products
      @product_dm = @products.select{|x| x.name.include?'DM'}.first
      @product_vc = @products.select{|x| x.name.include?'VC'}.first
      @product_ws = @products.select{|x| x.name.include?'WS'}.first
      @product_retail = @products.select{|x| x.retail_ws=='R'}.first

      if WarehouseExamining.duplicated(@product.id).blank?
        @warehouse_examining = WarehouseExamining.new(product_name: @product.name,\
          product_no_ws_id: @product.id, current_stock: @products.map(&:inventory).sum,\
          allocation: OrderProduct.allocation_products(@products.map(&:id)).map(&:qty).sum,\
          on_order: OrderProduct.on_order(@products.map(&:id)).map(&:qty).sum,\
          current_dm: @product_dm.nil? ? -1 : @product_dm.inventory,\
          current_vc: @product_vc.nil? ? -1 : @product_vc.inventory,\
          current_retail: @product_retail.nil? ? -1 : @product_retail.inventory,\
          current_ws: @product_ws.nil? ? -1 : @product_ws.inventory)
      else
        @warehouse_examining = WarehouseExamining.duplicated(@product.id).first
        @warehouse_examining.assign_attributes(current_stock: @products.map(&:inventory).sum,\
        allocation: OrderProduct.allocation_products(@products.map(&:id)).map(&:qty).sum,\
        on_order: OrderProduct.on_order(@products.map(&:id)).map(&:qty).sum,\
        current_dm: @product_dm.nil? ? -1 : @product_dm.inventory,\
        current_vc: @product_vc.nil? ? -1 : @product_vc.inventory,\
        current_retail: @product_retail.nil? ? -1 : @product_retail.inventory,\
        current_ws: @product_ws.nil? ? -1 : @product_ws.inventory)
      end

      @product.case_size = @product_ws.case_size if !@product_ws.nil? && @product.case_size.to_i==0

      @warehouse_examining.current_total = @warehouse_examining.current_stock.to_i + @warehouse_examining.allocation.to_i + @warehouse_examining.on_order.to_i
      @warehouse_examining.count_size = @product.case_size
    end
  end

  # Temporary
  # Will be moved to warehouse -> desktop version
  def review
    @warehouse_reviews = WarehouseExamining.pending
  end

  def warehouse_review
    params[:selected_product].each do |warehouse_id|
      examining = params[:warehouse][warehouse_id]
      product_no_ws = ProductNoWs.find(examining[:product_no_ws_id])
      # IMPORTANT
      # Update Product Inventory
      # Overwrite Master records
      product_no_ws.products.each do |product|
        if product.name.include?' DM'
          product.inventory_overwrite(examining['count_dm'].to_i, session[:user_id]) if examining['count_dm']
        elsif product.name.include?' VC'
          product.inventory_overwrite(examining['count_vc'].to_i, session[:user_id]) if examining['count_vc']
        elsif product.name.include?' WS'
          product.inventory_overwrite(examining['count_ws'].to_i, session[:user_id]) if examining['count_ws']
        elsif product.retail_ws=='R'
          product.inventory_overwrite(examining['count_retail'].to_i, session[:user_id]) if examining['count_retail']
        end
      end
      # Update examining and quit
      authorised = {authorised_staff_id: session[:user_id], authorised_date: Time.now().to_s(:db)}
      WarehouseExamining.find(examining[:id])
        .update_attributes(
          examining
            .permit(:count_size, :count_pack, :count_loose, :count_sample, :count_total,
              :count_dm, :count_vc, :count_ws, :count_retail).merge(authorised))
    end
    flash[:success] = 'Stock Updaetd!'
    redirect_to request.referrer
  end

  def fetch_product_details
    @product = Product.find(params[:product_id])
    respond_to do |format|
      format.js
    end
  end

  def product_inventory_overwrite
    if Staff.find(session[:user_id]).product_rights.zero?
      flash[:error] = 'No Authority'
      redirect_to request.referrer and return
    else
      params[:product].each {|product_id, inventory| Product.find(product_id).inventory_overwrite(inventory.to_i, session[:user_id])}
      flash[:success] = 'Stock Level Overwrote'
    end
    redirect_to request.referrer
  end

  def location
  end

  def fetch_product_winery
    if params[:producer_id]
      products = Producer.find(params[:producer_id]).products.where('inventory > 0')
      @product_no_ws = ProductNoWs.where(id: products.map(&:product_no_ws_id).uniq).order(:name)
      @producer = params[:producer_id]
    else
      @product_no_ws = ProductNoWs.where(id: params[:product_no_ws_id])
      @producer = params[:product_no_ws_id]
    end
    respond_to do |format|
      format.js
    end
  end

  # Flag for product Selection
  # Do Not Use

  # def fetch_product_selected
  #   unless session[:default_group].nil?
  #     product = StaffGroupItem.products(session[:default_group], params[:product_no_ws_id])
  #     product.delete if
  #     @product = ProductNoWs.find(params[:product_no_ws_id])
  #     @product.update(selected: (@product.selected.to_i==0)? 1 : 0 )
  #   end
  #   respond_to do |format|
  #     format.js
  #   end
  # end
end

private

def product_params
  params.require(:product).permit(:producer_id, :product_type_id, :warehouse_id,\
   :product_size_id, :product_no_ws_id, :name_no_ws, :name_no_vintage,\
   :product_no_vintage_id, :case_size, :product_package_type_id, :retail_ws,\
   :vintage, :name_no_winery_no_vintage, :price_id, :product_sub_type_id,\
   :blend_type, :order_1, :order_2, :combined_order, :producer_region_id,\
   :current, :display, :name_no_winery)
end

def warehouse_params
  params.require(:warehouse_examining).permit(:product_name, :product_no_ws_id,\
   :current_total, :allocation, :current_stock, :on_order, :count_pack, :count_loose,\
   :count_sample, :count_total, :difference, :count_ws, :count_dm, :count_vc, :count_retail,\
   :current_ws, :current_dm, :current_vc, :current_retail)
end
