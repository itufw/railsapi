module ContactHelper
  def update_cust_contact(params, contact_id)
    # ["0", '1', '2'....]
    items = params.keys().select {|x| x.start_with? 'status'}.map {|x| x.split('_').last}
    items.each do |item|
      if params['status_'+item] == 'Deleted'
        CustContact.filter_by_contact_and_customer(params['customer_id_'+item], contact_id).destroy_all
      else
        contact = CustContact.filter_by_contact_and_customer(params['customer_id_'+item], contact_id).first
        if contact.nil?
          contact = CustContact.new
          contact.customer_id = params['customer_id_'+item]
          contact.contact_id = contact_id
        end

        contact.position = params[:role]['role_'+item]
        contact.title = params['title_'+item]
        contact.phone = params['phone_'+item]
        contact.fax = params['fax_'+item]
        contact.email = params['email_'+item]
        contact.save
      end
    end
  end
end
