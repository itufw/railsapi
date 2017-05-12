require 'models_filter.rb'
# lead Helper
module LeadHelper
  include ModelsFilter

  def lead_filter(params)
    search_text = params['search']
    cust_style_id, = collection_param_filter(params, :cust_style, CustStyle)
    staff_id, = collection_param_filter(params, :staff, Staff)

    leads = CustomerLead.search(search_text).filter_staff(staff_id).filter_cust_style(cust_style_id)

    [leads, search_text]
  end
end
