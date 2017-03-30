module CalendarHelper
  def map_filter(params)
    cust_type = params[:selected_cust_type] || []
    selected_staff = params[:selected_staff] || []
    [cust_type, selected_staff]
  end
end
