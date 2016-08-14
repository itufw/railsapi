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
                @customers = Customer.where(staff_id: staff_id).search_for(@search_text).includes(:staff).order('actual_name ASC')
            else
                @customers = Customer.search_for(@search_text).includes(:staff).order('actual_name ASC')
            end
      else
          @customers = Customer.includes(:staff).order('actual_name ASC')
      end


  end

  def products

    @search_text = params[:search]

    @products = Product.search_for(@search_text).order('name ASC')

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
