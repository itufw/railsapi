class Projection < ActiveRecord::Base
    belongs_to :customer

    # filter orders by multiple customer_staffs relationship order by customer staffs
    def self.projecting_data(staff_ids)
        return all if staff_ids.nil?
        select('customer_name, q_lines, q_bottles, q_avgluc')
        .where('recent = ? and sale_rep_id IN (?)', 1, staff_ids) 
    end

end
