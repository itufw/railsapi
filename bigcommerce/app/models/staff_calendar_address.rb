# save the calendar cloud addresses for each staff
# this would be used in calendar controller and task controller
class StaffCalendarAddress < ActiveRecord::Base
  belongs_to :staff

  def self.filter_by_addresses(addresses)
    where('staff_calendar_addresses.calendar_address IN (?)', addresses)
  end

  def self.filter_by_ids(staff_ids)
    where('staff_calendar_addresses.staff_id IN (?)', staff_ids)
  end
end
