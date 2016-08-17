class ModelsController < ApplicationController

  before_action :confirm_logged_in
  
  def orders
  # 	limit = define_limit(params[:page])
  # 	@orders = Order.includes([{:customer => :staff}, :status]).order('id DESC').limit(limit[1]).offset(limit[0])
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


  def define_limit(param_page)
    if param_page.blank?
      page = 1
    else
      page = param_page.to_i
    end
  	limit_num = 20
  	limit_start = (page - 1) * limit_num
  	limit_end = limit_num * page
  	return [limit_start, limit_end]
  end


end
