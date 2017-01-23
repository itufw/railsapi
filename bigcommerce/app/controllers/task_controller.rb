require 'models_filter.rb'
require 'dates_helper.rb'

class TaskController < ApplicationController
  before_action :confirm_logged_in

  include ModelsFilter
  include DatesHelper

  def add_task
    @start_date = return_end_date_invoices(params[:start_date])
    @end_date = return_end_date_invoices(params[:end_date])

  end
end
