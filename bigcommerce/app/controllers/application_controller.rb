class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
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

    def admin_logged_in
      unless session[:user_id] && (session[:user_type].eql? "Admin")
        flash[:notice] = "Please Log In or Do not have authorise"
        redirect_to :back
        return false
      else
        return true
      end
    end

    def manager_logged_in
      unless session[:user_id] && ((session[:user_type].eql? "Admin") || (session[:user_type].eql? "Manager"))
        flash[:notice] = "Please Log In or Do not have authorise"
        redirect_to :back
        return false
      else
        return true
      end
    end

    def accounts_logged_in
      unless session[:user_id] && ((session[:user_type].eql? "Admin") || (session[:user_type].eql? "Manager") || (session[:user_type].eql? "Accounts"))
        flash[:notice] = "Please Log In or Do not have authorise"
        redirect_to :back
        return false
      else
        return true
      end
    end

end
