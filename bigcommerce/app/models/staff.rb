require 'csv'

class Staff < ActiveRecord::Base
    include RailsSortable::Model

    has_many :customers
    has_many :customer_leads
    has_many :orders
    has_many :staff_daily_samples
    has_many :staff_groups

    has_many :staff_time_periods
    has_many :staff_calendar_addresses
    has_one :default_average_period
    has_one :default_start_date

    # validates :email, unique: true

    has_secure_password
    set_sortable :staff_order
    # Create a new user
    # Staff.create(name: , email: , password: , password_confirmation: )

    # get active sale staffs and Lucia (id = 8)
    def self.active_sales_staff
        where('(active = 1 and user_type LIKE "Sales%") or id = 8')
    end

    def self.active_sales_staff_plus(staff_id)
        where('(active = 1 and user_type LIKE "Sales%") OR (id = ?)', staff_id)
    end

    ### TO BE DEPRECATED
    def self.sales_list
      where(active: 1, sales_list_right: 1)
    end

    ### TO BE DEPRECATED
    def self.get_staffs arr_ids
        select('id, nickname').where(:id => arr_ids)
    end

    def self.calendar_list(staff_id = nil)
      where(active: 1, calendar_right: 1) if staff_id.nil?
      where('active = 1 AND (calendar_right = 1 OR id = ?)', staff_id)
    end

    def self.active
        where('active = 1').order('user_type DESC, staff_order ASC')
    end

    def self.filter_by_id(staff_id)
        find(staff_id)
    end

    def self.filter_by_ids(staff_ids)
        return Staff.active if staff_ids.nil? || staff_ids.blank?
        where('staffs.id IN (?)', staff_ids)
    end

    def self.filter_by_email(email)
        where("staff.email = \"#{email}\"").first
    end

    def self.filter_by_calendar_email(emails)
      joins(:staff_calendar_addresses).where('staff_calendar_addresses.calendar_address IN (?)', emails.uniq)
    end

    def self.filter_by_emails(emails)
      return Staff.active if emails.nil? || emails.blank?
      where('staffs.email IN (?)', emails)
    end

    ### TO BE DEPRECATED
    def self.nickname
        pluck('id, nickname')
    end

    ### TO BE DEPRECATED
    def self.id_nickname_hash(staff_id)
        Staff.where(id: staff_id).pluck('id,nickname').to_h
    end

    ### TO BE DEPRECATED
    def self.display_report(staff_id)
        find(staff_id).display_report
    end

    # return true (1) if the current staff can view the current report
    # otherwise return false (0)
    def report_viewable
       display_report.to_i
    end

    def self.can_update(staff_id)
        find(staff_id).can_update
    end

    def self.filter_by_state(state)
      where(state: state)
    end

    def self.order_by_order
        order(:staff_order)
    end

    def name
      nickname
    end

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
    #                                                                                       #
    #                                                                                       #
    #                                      NEWLY ADDED                                      #
    #                                         VCHAR                                         #
    #                                                                                       #
    #                                                                                       #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

    # returns a collection of active record objects of staff, ie.
    # [
    #   #<Staff id: 5, nickname: "Harry", report_to: 5>, 
    #   #<Staff id: 44, nickname: "Candice", report_to: 44>,
    #   ...
    # ]
    def self.get_staffs_report_to
        select('id, nickname, report_to').sales_list.order_by_order
    end
end
