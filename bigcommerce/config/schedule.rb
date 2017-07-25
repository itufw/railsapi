# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
require "active_support/all"

Time.zone = "Melbourne"

set :environment, "production"

set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 5.minutes do
	rake "updates:models"
end

every 1.hours do
	rake "updates:event_update"
end

every 1.day, :at => Time.zone.parse('6:00 pm').utc do
	rake "updates:balanceupdate"
end

every 1.day, :at => Time.zone.parse('8:30 pm').utc do
	rake "updates:timeperiods"
end

every 1.day, :at => Time.zone.parse('6:30 am').utc do
	rake "updates:zomato_update"
end

every 1.day, :at => Time.zone.parse('10:30 am').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('10:00 pm').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('5:45 pm').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('9:15 am').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('6:00 am').utc do
	rake 'updates:manifest_update'
end

every '30 10-17,0 * * *' do
	rake 'updates:package_trace'
end
