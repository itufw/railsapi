module ModelsHelper

  # Returns a title for the Orders page
  # Orders page can either be navigated to from the navbar - which displays all orders
  # Or it can be navigated to by the Dashboard, where it will have a start_date, end_date
  # and/or Staff

  # Depending on those params, this functions returns a page header
  def orders_page_title(staff_nickname, start_date, end_date)
  	unless start_date.nil? || start_date.blank?
  	  unless staff_nickname.nil?
  	  	return "Orders for #{staff_nickname} from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
  	  else
  	  	return "Orders from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
  	  end
  	else
  	  return "Orders"
  	end
  end

  def customer_filter_path
    if current_page?(action: 'incomplete_customers')
      return "incomplete_customers"
    else
      return "all"
    end
  end
end
