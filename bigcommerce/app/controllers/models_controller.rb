class ModelsController < ApplicationController

  before_action :confirm_logged_in
  
  def orders
      @staffs = active_sales_staff
      @statuses = Status.all

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

      if !customer_ids.nil?
          @orders = Order.includes([{:customer => :staff}, :status]).status_staff_filter(status_id, staff_id).where('customers.id IN (?)', customer_ids).references(:customers).page(params[:page]).order('orders.id DESC')
      else
          @orders = Order.includes([{:customer => :staff}, :status]).status_staff_filter(status_id, staff_id).page(params[:page]).order('orders.id DESC')
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

    @products = Product.filter(@search_text, producer_country_id, product_sub_type_id).page(params[:page]).order('name ASC')

  end

end
