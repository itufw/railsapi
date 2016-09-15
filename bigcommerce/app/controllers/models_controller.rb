require 'models_filter.rb'

class ModelsController < ApplicationController

  before_action :confirm_logged_in

  include ModelsFilter
  
  def orders

    results_val = order_param_filter(params)
    @staff = results_val[0]
    @status = results_val[1]
    @orders = results_val[2].page(params[:page])
    @search_text = results_val[3]
    @start_date = params[:start_date]
    @end_date = params[:end_date]



  end


  def customers

  end

  def products

  end

end
