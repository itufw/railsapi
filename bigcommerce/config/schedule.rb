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

every '30 9-19,0 * * *' do
	rake 'updates:package_trace'
end

every 1.day, :at => '10:45 pm' do
	rake 'updates:wake_signatures'
end

every 1.day, :at => '9:00 am' do
	rake "updates:balanceupdate"

	rake "updates:timeperiods"
end

every 1.day, :at => '11:45 am' do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => '4:00 pm' do
	rake 'updates:manifest_update'
end

every 1.day, :at => '7:00 pm' do
  rake "xero_invoice_sync:sync"

	rake "updates:zomato_update"

	rake 'updates:manifest_update'

	rake "updates:sales_rate_update"
end
