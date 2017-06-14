# Record Daily Samples
class StaffDailySample < ActiveRecord::Base
  belongs_to :staff
  belongs_to :product

  def staff_record(staff_id, product_id)
    self.staff_id = staff_id
    self.product_id = product_id
    self.date = Date.today.to_s(:db)
    save
  end

  def self.record_exist?(staff_id, product_id)
    where('staff_id = ? AND product_id = ?', staff_id, product_id)
  end

  def self.staff_samples(staff_id)
    where('staff_id = ?', staff_id)
  end
end
