module ApplicationHelper

  def title(page_title)
  	content_for(:title) { page_title }
  end

  def display_num(value)
	number_with_delimiter(number_with_precision(value, precision: 2))
  end

  def date_format(date)
  	date.strftime('%A %d/%m/%y')
  end

end
