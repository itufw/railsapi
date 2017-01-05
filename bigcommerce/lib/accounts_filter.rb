module AccountsFilter

  def customer_outstanding_greater_zero(params)
    customers = Customer.include_all.xero_contact_is_not_null.outstanding_is_greater_zero
    return customers
  end
end
