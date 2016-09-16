module ModelsHelper

  # Returns a title for the Orders page
  # Orders page can either be navigated to from the navbar - which displays all orders
  # Or it can be navigated to by the Dashboard, where it will have a start_date, end_date
  # and/or Staff

  # Depending on those params, this functions returns a page header
  def orders_page_title(staff_nickname, start_date, end_date)
  	unless start_date.nil? || start_date.blank?
  	  unless staff_nickname.nil?
  	  	return "Orders for #{staff_nickname} from #{date_format_orders(start_date)} - #{date_format_orders(end_date)}"
  	  else
  	  	return "Orders from #{date_format_orders(start_date)} - #{date_format_orders(end_date)}"
  	  end
  	else
  	  return "Orders"
  	end
  end
end
