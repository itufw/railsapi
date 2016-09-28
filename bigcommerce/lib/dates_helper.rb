module DatesHelper

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
  def get_last_weeks_date(num_times, end_date)
    last_weeks_dates = []
    current_date = end_date
    num_times.times do
      last_weeks_dates.push(current_date.last_week)
      current_date = current_date.last_week
    end
    return last_weeks_dates
  end

  # Gives a sorted array of dates
  # where first element is the date, number of periods before the end_date
  # a period can be defined by a function
  def periods_from_end_date(num_periods, end_date)
    all_dates = []
    if end_date.beginning_of_week == end_date
      # It is a Monday
      all_dates.push(end_date)
      return (all_dates + get_last_weeks_date(num_periods, end_date)).sort
    else
      # Not a Monday
      # That week's monday - given end date will be one period
      # num_periods - 1 will be normal Weekly periods
      all_dates.push(end_date.next_day)
      all_dates.push(end_date.beginning_of_week)
      return (all_dates + get_last_weeks_date(num_periods - 1, end_date.beginning_of_week)).sort      
    end
  end

  # Returns a hash where key is the week number and value is an array of start date and end date
  def pair_dates(dates_a)
    paired_dates_a = {}
    dates_a.each_cons(2) {|date, next_date| paired_dates_a[convert_to_week_num(date)] = [date, next_date] unless date.equal? dates_a.last}
    return paired_dates_a
  end

  # Convert date to week number
  def convert_to_week_num(date)
    return date.strftime('%U').to_i
  end

end