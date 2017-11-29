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
           when 'Management'
             'Sales'
           else
             'Operations'
           end
    role
  end

  # function collection ; subject collection; methods collection;
  # default function value; promotion rate
  def function_search(params, parent_task = nil)
    function = staff_function(session[:user_id])
    # Sales/ Operations/ Accounting
    if parent_task.nil?
      default_function = default_function_type(session[:authority])
    else
      default_function = parent_task.function || default_function_type(session[:authority])
    end
    params[:selected_function] = params[:selected_function] || default_function

    subjects = TaskSubject.all
    subjects = subjects.select { |x| x.function == params[:selected_function] }

    [function, subjects]
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

  # ------------------------------------------
  # insert or update for db
  def note_save(note_params, staff_id, parent_task = nil)
    note = Task.new
    note.response_staff = staff_id
    note.last_modified_staff = staff_id
    note.update_attributes(note_params)
    note.is_task = (note.end_date.nil?) ? 0 : 1
    note.expired = 0
    note.end_date = note.start_date if note.end_date.nil?
    note.parent_task = parent_task unless parent_task.nil?
    note.save
    note
  end

  def note_update(note_params, staff_id, activity_id)
    note = Task.find(activity_id)
    note.update_attributes(note_params)
    note.last_modified_staff = staff_id
    note.updated_at = Time.now()
    note.save
    note
  end

  def relation_destory(activity_id)
    TaskRelation.where('task_id = ?', activity_id).destroy_all
  end

  def relation_save(params, task)
    relation_destory(task.id)

    task_id = task.id
    task.gcal_status = ('yes' == params['event_column']) ? 'pending' : 'na'
    customers = params.keys.select { |x| x.start_with?('customer ') }.map(&:split).map(&:last)
    customer_id = customers.first
    assign_to = 'customer' unless customer_id.nil?
    staffs = params.keys.select { |x| x.start_with?('staff ') }.map(&:split).map(&:last)
    leads = params.keys.select { |x| x.start_with?('lead ') }.map(&:split).map(&:last)
    assign_to = 'lead' if customer_id.nil?
    customer_id = leads.first if customer_id.nil?

    contacts = params[:selected_contact] || []

    [customers, staffs, leads, contacts].max_by(&:length).each do |f|
      tr = TaskRelation.new
      tr.task_id = task_id
      tr.customer_id = customers.delete_at(0)
      tr.staff_id = staffs.delete_at(0)
      tr.customer_lead_id = leads.delete_at(0)
      tr.contact_id = contacts.delete_at(0)
      tr.save
    end
    task.save
    [customer_id,assign_to]
  end

  def product_note_version_update(activity_id)
    ProductNote.where('task_id = ?', activity_id).update_all('version = version + 1')
  end

  def product_note_save(params, staff_id, task_id)
    product_note_version_update(task_id)
    product_list = params.keys.select { |x| x.start_with?('note ') }.map(&:split).map(&:last)
    product_list.each do |product_id|
      pn_save(product_id, staff_id, task_id, params['buy_wine'], params['tasted'])
    end
  end

  def pn_save(product_id, staff_id, task_id, buy_list, tasted_list)
    pn = ProductNote.new
    pn.task_id = task_id
    pn.created_by = staff_id
    pn.product_id = product_id
    pn.rating = params['rate ' + product_id]
    pn.note = params['note ' + product_id]
    pn.price = params['price ' + product_id]
    pn.product_name = params['product_name ' + product_id]
    pn.price_luc = params['price_luc ' + product_id]
    pn.intention = (buy_list.include? product_id) ? 1 : 0 unless buy_list.nil?
    pn.tasted = (tasted_list.include? product_id) ? 1 : 0 unless tasted_list.nil?
    pn.version = 0
    pn.save
  end

  def task_product_note(params, task, staff_id)
    if params['selected_wine_note'].nil?
      product_note_save(params, staff_id, task.id)
    elsif !params['selected_wine_note'].blank?
      task.pro_note_include = params['selected_wine_note'].join(',')
      task.save
    end
  end

  def find_sample_products(staff_id)
    customer_id = Staff.find(staff_id).pick_up_id || 2086
    products = []
    Order.where(customer_id: customer_id).order('id DESC').limit(10).each do |order|
      products += order.products
      return products if products.count >= 20
    end
    products
  end

  # -------------------------
  # Task insert
end
