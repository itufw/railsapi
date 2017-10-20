class ProductStatus < ActiveRecord::Base
  has_many :product_no_ws

  def self.status_update(country_short_name, monthly_supply)
    case country_short_name
    when 'SPA', 'ARG'
      return nil if monthly_supply > 4

      if monthly_supply<2
        return where('name Like "%Allocation Needed%"').first.id
      elsif monthly_supply<3
        return where('name Like "%Exist%"').first.id
      else
        return where('name Like "%Ask%"').first.id
      end

    when 'CHI'
      return nil if monthly_supply > 5

      if monthly_supply<3
        return where('name Like "%Allocation Needed%"').first.id
      elsif monthly_supply<4
        return where('name Like "%Exist%"').first.id
      else
        return where('name Like "%Ask%"').first.id
      end

    when 'URG'
      return nil if monthly_supply > 6

      if monthly_supply<4
        return where('name Like "%Allocation Needed%"').first.id
      elsif monthly_supply<5
        return where('name Like "%Exist%"').first.id
      else
        return where('name Like "%Ask%"').first.id
      end
    end
  end
end
