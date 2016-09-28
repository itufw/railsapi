class ModelsController < ApplicationController

  before_action :confirm_logged_in
  
  def orders
      @staffs = active_sales_staff
      @statuses = Status.all
      @page_header = "Orders"

      staff_id = nil
      status_id = nil
      if params.has_key?(:commit)
          @search_text = params[:search]
          customer_ids = Customer.search_for(@search_text).pluck("id")
          if !params[:staff][:id].blank?
              staff_id = params[:staff][:id]
              @staff = Staff.where(id: staff_id).first
          end
          if !params[:status][:id].blank?
              status_id = params[:status][:id]
              @status = Status.where(id: status_id).first
          end
      end
      if !params[:start_date].nil? && !params[:start_date].blank?
          @start_date = params[:start_date]
          start_time = Time.parse(@start_date) 
      end
      if !params[:end_date].nil? && !params[:end_date].blank?
          @end_date = params[:end_date]
          end_time = Time.parse(@end_date)
          @page_header = "Orders from #{params[:start_date].to_date.strftime('%A  %d/%m/%y')} - #{params[:end_date].to_date.strftime('%A  %d/%m/%y')}"
      end
      
      if !params[:start_date].nil?
        if !params[:staff_id].nil?
          staff_id = params[:staff_id]
          staff_nickname = params[:staff_nickname]
          @page_header = "Orders for #{staff_nickname} from #{params[:start_date].to_date.strftime('%A  %d/%m/%y')} - #{params[:end_date].to_date.strftime('%A  %d/%m/%y')}"
          @staff = Staff.where(id: staff_id).first
        else
          
        end
      end


      if !customer_ids.nil?
          @orders = Order.includes([{:customer => :staff}, :status]).status_staff_filter(status_id, staff_id, start_time, end_time).where('customers.id IN (?)', customer_ids).references(:customers).page(params[:page]).order('orders.id DESC')
      else
          @orders = Order.includes([{:customer => :staff}, :status]).status_staff_filter(status_id, staff_id, start_time, end_time).page(params[:page]).order('orders.id DESC')
      end

  end


  def customers
      @staffs = active_sales_staff

      if params.has_key?(:commit)
          @search_text = params[:search]
          if !params[:staff][:id].blank?
              staff_id = params[:staff][:id]
              @staff = Staff.where(id: staff_id).first
          end
      end

      @customers = Customer.includes(:staff).staff_search_filter(@search_text, staff_id).page(params[:page]).order('actual_name ASC')
              

  end

  def products

      @countries = ProducerCountry.all
      @sub_types = ProductSubType.all

      staff_id = nil
      producer_country_id = nil
      product_sub_type_id = nil

      if params.has_key?(:commit)
        @search_text = params[:search]
        if !params[:producer_country][:id].blank?
            producer_country_id = params[:producer_country][:id]
            @producer_country = ProducerCountry.where(id: producer_country_id).first
        end
        if !params[:product_sub_type][:id].blank?
            product_sub_type_id = params[:product_sub_type][:id]
            @product_sub_type = ProductSubType.where(id: product_sub_type_id).first
        end
      end

    @product_pending_count = Product.filter(@search_text, producer_country_id, product_sub_type_id).includes([{:order_products => :order}]).where('orders.status_id = 1').references(:orders).group('order_products.product_id').sum('order_products.qty')

    @products = Product.filter(@search_text, producer_country_id, product_sub_type_id).page(params[:page]).order('name ASC')

  end

  def return_pending_stock(product_pending_count_map, product_id)
    if product_pending_count_map.has_key?(product_id)
      return product_pending_count_map[product_id]
    else
      return 0
    end
  end

  helper_method :return_pending_stock

end
