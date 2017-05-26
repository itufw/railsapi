require 'activity_helper.rb'

# The replacement of task controller
class ActivityController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true

  include ActivityHelper

  # insert notes
  # following Dropbox -> pages -> Activity
  def add_note
    @customers, @contacts \
      = customer_search(params)

    # activity helper -> get the functions/subjects/methods from json request
    @function, @subjects, @methods, @function_role, @promotion, @portfolio \
      = function_search(params)
    # @products = product_search
    @note = Task.new
  end

end
