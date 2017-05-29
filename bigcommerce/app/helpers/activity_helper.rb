# support activity controller
module ActivityHelper
  def customer_search(params)
    customers = Customer.all
    contacts = Contact.filter_by_customer(params['selected_customers'])

    [customers, contacts]
  end

  # function collection
  def staff_function(staff_id)
    staff = Staff.find(staff_id)
    case staff.user_type
    when 'Sales Executive'
      function = TaskSubject.distinct_function_user('Sales Executive')
    else
      function = TaskSubject.distinct_function
    end
    function
  end

  # default value of function collection
  def default_function_type(user_role)
    role = case user_role
           when 'Accounts'
             'Accounting'
           when 'Sales Executive'
             'Sales'
           else
             'Operations'
           end
    role
  end

  # function collection ; subject collection; methods collection;
  # default function value; promotion rate
  def function_search(params)
    function = staff_function(session[:user_id])
    # Sales/ Operations/ Accounting
    default_function = default_function_type(session[:authority])
    params[:selected_function] = params[:selected_function] || default_function
    promotion = Promotion.all

    subjects = TaskSubject.all
    subjects = subjects.select { |x| x.function == params[:selected_function] }
    methods = TaskMethod.all
    portfolio = Portfolio.all
    [function, subjects, methods, default_function, promotion, portfolio]
  end

  def product_search
    products = Product.stock?
    [products]
  end

  def product_click(products, product_selected)
    return nil if product_selected.nil?
    product = products.select { |x| x.id == product_selected }.first
    return nil if product.nil?
    product
  end
end
