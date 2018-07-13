module DisplayHelper

  # get a list of staff to be dislpayed on the sale report
  # return
  # [
  #   nil, 
  #   {
  #     5=>"Harry", 
  #     54=>"Mat", 
  #     44=>"Candice", 
  #     55=>"Amy", 
  #     50=>"Ben", 
  #     ...
  #   }
  # ]
  ### TO BE DEPRECATED
  def display_reports_for_sales_dashboard(staff_id)
  	# display all staffs
  	if reports_access_open(staff_id) == 1
  	  staffs = Staff.sales_list.order_by_order.nickname.to_h
  	  return nil, staffs
  	# display only the one
  	else
  	  staff = Staff.id_nickname_hash(staff_id)
      return staff_id, staff
    end
  end

  ### TO BE DEPRECATED
  def reports_access_open(staff_id)
    display_val = (Staff.display_report(staff_id)).to_i
    return display_val
  end

  ### TO BE DEPRECATED as duplicate the one in applicaton_helper.rb
  def allow_to_update(staff_id)
    return Staff.can_update(staff_id).to_i == 1
  end

end
