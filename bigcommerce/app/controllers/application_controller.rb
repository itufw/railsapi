class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  

  	def get_customer_name(customer_object)
        if customer_object.nil?
          return ""
        end

        if customer_object.actual_name.nil?
          return customer_object.firstname + ' ' + customer_object.lastname
        else
          return customer_object.actual_name
        end

    end

    helper_method :get_customer_name

    def calculate_product_price(product_calculated_price, retail_ws)

      if retail_ws == 'WS'
        return product_calculated_price * 1.29
      else
        return product_calculated_price
      end

    end

    helper_method :calculate_product_price

    
    def active_sales_staff
      return Staff.where('active = 1 and user_type LIKE "Sales%"')
    end

    def customer_name(firstname, lastname, actual_name)
        if actual_name.nil?
          return firstname + " " + lastname
        else
          return actual_name
        end

    end

    private

    def confirm_logged_in
      unless session[:user_id]
        flash[:notice] = "Please Log In"
        redirect_to controller: 'access', action: 'login'
        return false
      else
        return true
      end
    end


end
