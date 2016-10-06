module DisplayHelper

  def display_reports_for_sales_dashboard(staff_id)
  	# display all staffs
  	if reports_access_open(staff_id) == 1
  	  staffs = Staff.active_sales_staff.nickname.to_h
  	  return nil, staffs
  	# display only the one
  	else
  	  staff = Staff.id_nickname_hash(staff_id)
      return staff_id, staff
    end
  end

  def reports_access_open(staff_id)
    display_val = (Staff.display_report(staff_id)).to_i
    return display_val
  end

end