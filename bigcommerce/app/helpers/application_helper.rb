module ApplicationHelper
  def log desc, data
    logger.info ""
    logger.info "--------------------------- : " + desc + " : --------------------------- BEGINS"
    logger.info data
    logger.info "=========================== : " + desc + " : =========================== ENDS"
    logger.info ""
  end

  # Sets Title of a page
  def title(page_title)
    content_for(:title) { page_title }
  end

  def allow_to_update(staff_id)
    Staff.can_update(staff_id).to_i == 1
  end

  # Displays a number with 2 precision and with commas
  def display_num(value)
    number_with_delimiter(number_with_precision(value, precision: 2))
  end

  def display_overall_stat(value, sum_param)
    sum_param == 'Qty' ? number_with_delimiter(value) : display_num(value)
  end

  # Displays a date in the form 'Day of the week, Day/Month/Year'
  def date_format(date)
    date.to_date.strftime('%a %d/%m/%y')
  end

  # Displays a date in the form 'Day of the week, Day/Month/Year'
  def short_date(date)
    date.to_date.strftime('%d-%m-%Y')
  end

  # Displays date in the form Day/Month/Year
  def date_format_orders(date)
    date.to_date.strftime('%d/%m/%y') unless date.nil?
  end

  # Takes a Customer Object as input, returns its name
  def customer_name(customer)
    if customer.nil?
      ' '
    else
      Customer.customer_name(customer.actual_name, customer.firstname, customer.lastname)
    end
  end

  # Returns name of Status
  def order_status(status)
    status.name
  end

  # Return the latest shipping status
  def shipping_status(order)
    if order.track_number.nil? || order.track_number==""
      # return civic if courier status is 2 even tracking info is not provided
      return 'CIVIC' if order.courier_status_id==2
      
      records = FastwayTrace.where(id: FastwayTrace.track_order(order.id).group('LabelNumber').maximum('id').values())
    elsif order.courier_status_id == 4
      records = FastwayTrace.where(id: FastwayTrace.where('LabelNumber IN (?)', order.track_number.split(';')).group('LabelNumber').maximum('id').values())
    elsif order.courier_status_id == 1
      return ''
    else
      return order.courier_status.description.to_s + " " + order.track_number
    end

    return 'Fastway Booked' if records.blank? && order.courier_status_id==4
    return '' if records.blank?

    record_status = records.map(&:Description).uniq
    return 'Manual Check Required' if record_status.count > 1
    record_status.first
  end

  def all_staffs
    Staff.active_sales_staff.order_by_order
  end

  # Returns Staff's nickname
  # Takes in a staff object as input
  def staff_nickname_direct(staff)
    staff.nickname unless staff.nil?
  end

  # Takes in a customer object as input and returns staff's nickname
  def staff_nickname(customer)
    customer.staff.nickname unless customer.nil?
  end

  def staff_for_customer(customer)
    return customer.staff unless customer.nil?
  end

  # Paginates model unless the number of rows are less than 15
  # 15 is the paginate limit set in every model
  def paginate(model)
    will_paginate model unless model.count < 30
  end

  # Checks if key exists in hash
  # If yes returns the corresponding value for that key
  # Otherwise returns empty string
  def exists_in_h(hash, key)
    if hash.key? key
      hash[key]
    else
      ' '
    end
  end

  # if key exists in hash, turn hash[key] value
  # Otherwise returns 0
  def exists_in_h_int(hash, key)
    if hash.key? key
      hash[key]
    else
      0
    end
  end

  def convert_empty_string_to_int(val)
    if val.to_s.strip.empty?
      0
    else
      val
    end
  end

  def since_days(date_today, num_days)
    num_days.days.since(date_today)
  end

  def sum_values_of_hash(hash)
    hash.values.sum
  end

  def calculate_product_price(product_calculated_price, retail_ws)
    if retail_ws == 'WS'
      product_calculated_price * 1.29
    else
      product_calculated_price
    end
  end

  # Takes input staff id and a Hash like {[staff_id, date] => sum}
  # Returns a Hash like {date => sum} for that particular staff_id
  # Here sum can be order_totals/qty..etc for that particular staff on that date
  # Also works for product_id's hash.
  def give_sum_date_h(object_id, date_sum_object_h)
    filter_by_object = date_sum_object_h.select { |key, _sum| key[0] == object_id }

    sum_date_h = {}
    filter_by_object.each { |key, sum| sum_date_h[new_key(key)] = sum }
    sum_date_h
  end

  # If hash is like {[id, date] => sum} then return date
  # Sometimes the hash is like {[id, date, year] => sum}
  # then return [date, year]
  def new_key(key)
    new_key = if key[1..-1].count == 1
                key[1]
              else
                key[1..-1]
              end
    new_key
  end

  # format the phone number for accounting header
  def num_to_phone(num)
    return '--' if num.nil? || num.length < 9

    num.gsub!(/[^\d]/, '')
    return "0#{num[0..2]} #{num[3..5]} #{num[6..8]}" if num.length == 9
    return "#{num[0..3]} #{num[4..6]} #{num[7..9]}" if num[1] == '4'
    "#{num[0..1]} #{num[2..5]} #{num[6..9]}"
  end

  def fetch_note_children(notes)
    children = []
    notes.each do |n|
      children += n.children unless n.children.nil? || n.children.blank?
    end
    children
  end

  # task priority display
  def task_priority_display(task_priority)
    case task_priority
    when 1
      'LOWEST'
    when 2
      'LOW'
    when 4
      'HIGH'
    when 5
      'IMPORTANT'
    else
      'MEDIUM'
    end
  end

  def user_full_right(_authority=nil)
    return true if %w[Admin Management Accounts].include? session[:authority]
    false
  end

  def user_accountant(authority=nil)
    return true if (%w[Accounts].include? session[:authority]) || 52==session[:user_id]
    false
  end

  def it_working(staff_id)
    return true if staff_id == 52
    false
  end

  def update_missing_staff_id
    orders = Order.where(staff_id: nil)
    orders.each do |o|
      next if o.customer_id < 1
      o.staff_id = Customer.find(o.customer_id).staff_id
      o.save
    end
  end

  def current_user_sales?(_authority)
    return true if %w['Sales Executive'].include? session[:authority]
    false
  end

  def warehouse_section(column, row)
    return nil if (column.to_s=='') || (row.to_i==0)
    row = row.to_i

    case column
    when 'A', 'B', 'C'
      return 1 if (1..5).include?row
      return 2 if (6..10).include?row
      return 3
    when 'D', 'E', 'F'
      return 4 if (1..5).include?row
      return 5 if (6..10).include?row
      return 6
    when 'G', 'H', 'I'
      return 7 if (1..5).include?row
      return 8 if (6..10).include?row
      return 9
    else
      return 10 if (1..5).include?row
      return 11 if (6..10).include?row
      return 12
    end
  end
end
