class AccessController < ApplicationController

  before_action :confirm_logged_in, :except => [:login, :attempt_login, :logout]

  def login
    render layout: 'login'
    # login form
  end

  def attempt_login
    if params[:username].present? && params[:password].present?
      found_user = Staff.where(logon_details: params[:username]).first
      if found_user
        authorized_user = found_user.authenticate(params[:password])
      end
    end

    if authorized_user
      # TODO : mark user as logged in
      session[:user_id] = authorized_user.id
      session[:username] = authorized_user.nickname
      session[:arthority] = authorized_user.user_type
      flash[:success] = "You are now logged in."
      redirect_to controller: 'sales', action: 'sales_dashboard'
    else
      flash[:error] = "Invalid username/password combination"
      redirect_to action: 'login'
    end

  end

  def logout
    session[:user_id] = nil
    session[:username] = nil
    flash[:success] = "Logged out"
    redirect_to action: 'login'
  end



end
