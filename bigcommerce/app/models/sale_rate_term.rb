class SaleRateTerm < ActiveRecord::Base
  def self.standard_term
    where(id: [1, 2, 3, 4])
  end
end
