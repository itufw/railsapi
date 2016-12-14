module Dates
  # In a dashboard a period defines one column.
  # Each column has a start date and an end date
  # A user can choose these start and end dates to be divided into
  # weekly segments, monthly or quarterly

  def return_date_given(params)
    date_param = params[:selected_date]

    if date_param.blank?
      date_given = ""
    else
      date_given =  date_param[:selected_date].to_date
    end
    return date_given
  end

  def return_end_date(date_given)
    if date_given.blank?
      return Date.today
    else
      return date_given
    end
  end
# If a set date isnt given then start of the week is current week's start
  # if date is given, then start of the week is given date

  # End date in any case is 7 days after the start date

  # Returns an array containing week's date
  def this_week(date_given)

  	if date_given.blank?
  	  start_date = (Date.today).at_beginning_of_week
  	else
  	  start_date = date_given
  	end

  	end_date = 6.days.since(start_date)

  	return (start_date..end_date).to_a
  end

  # Returns an array of dates 
  # All of last week's dates based on the start date
  def last_week(start_date)

  	last_week_start_date = start_date - 7.days
  	last_week_end_date = 6.days.since(last_week_start_date)

  	return (last_week_start_date..last_week_end_date).to_a
  end

  # Make a hash like {date => [date, date]}
  # Need this to make partial views more flexible
  def make_daily_dates_map(dates_a)
    dates_map = {}
    dates_a.each {|d| dates_map[d] = [d, d.next_day]}
    return dates_map
  end

  # Get an array of last weeks' start dates
  def get_last_periods_date(num_times, end_date, date_function)
    last_periods_dates = []
    current_date = end_date
    num_times.times do
      last_periods_dates.push(current_date.send(date_function))
      current_date = current_date.send(date_function)
    end
    return last_periods_dates
  end

  # Returns a sorted array of dates
  # num_periods is the number of columns the user wants
  # end_date is the last date in the last column
  # period_type is how the dates needs to be divided - weekly, monthly or quarterly

  # Start from the end date, according to the period type, go to the start date
  # for that column
  # repeat this till we reach the required numbers of columns
  def dates_a_for_periods(num_periods, end_date, period_type)
    all_dates = []
    # rails has pre-defined date functions
    # depending on the period type tell me the beginning_function 
    # i.e. given a date, how do I get the start date of that period
    # eg. Given 3rd December 2016, I want the start date of the month i.e. 1st December 2016
    # my beginning function is :beginning_of_month
    # similarly last_function gives the last date in the period
    beginning_function, last_function = period_date_functions(period_type)

    # Orders table needs the date of the next day of the date you want the calculation to end at
    all_dates.push(end_date.next_day)
    all_dates.push(end_date.send(beginning_function))
    return (all_dates + get_last_periods_date(num_periods - 1, end_date.send(beginning_function), last_function)).sort      
  end

  # Returns period_type specific values
  # first value - how to calculate the date of the beginning of a period
  # second value - how to calculate the start date of last period
  # third value - string for group_by_date functions
  # fourth value - function that converts date to period_number 
  def period_date_functions(period_type)
    if period_type == "weekly"
      return ["beginning_of_week".to_sym, "last_week".to_sym, "group_by_week_created", :convert_to_week_num]
    elsif period_type == "monthly"
      return ["beginning_of_month".to_sym, "last_month".to_sym, "group_by_month_created", :convert_to_month_num]
    elsif period_type == "quarterly"
      return ["beginning_of_quarter".to_sym, "last_quarter".to_sym, "group_by_quarter_created", :convert_to_quarter_num]
    else
      return ["".to_sym, "".to_sym]
    end
  end


  # Returns a hash where key is the week number and value is an array of start date and end date
  def pair_dates(dates_a, period_type)
    convert_function = period_date_functions(period_type)[3]
    paired_dates_a = {}
    dates_a.each_cons(2) {|date, next_date| paired_dates_a[send(convert_function, date)] = [date, next_date] unless date.equal? dates_a.last}
    return paired_dates_a
  end

  # Convert date to week number
  def convert_to_week_num(date)
    return date.strftime('%U').to_i
  end

  def convert_to_month_num(date)
    return [date.month.to_i, date.year.to_i]
  end

  def convert_to_quarter_num(date)
    return [((date.month.to_i - 1) / 3) + 1, date.year.to_i]
  end

  # def calculate_invoice_due_date(date_created, customer)
  #   num_days_since_date_created = Customer.due_date_num_days(customer)
  #   return num_days_since_date_created.since(date_created)
  # end

      
end