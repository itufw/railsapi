module AccountsHelper

  def date_column_checked(date_column)
    if "due_date".eql? date_column
      # @checked_due_date = true
      # @checked_invoice_date = false
      return true, false
    end
    return false, true
  end

  def monthly_checked(monthly)
    if "monthly".eql? monthly
      # @checked_due_date = true
      # @checked_invoice_date = false
      return true, false
    end
    return false, true
  end

  def email_preview(email_ratio)
    if "no".eql? email_ratio
      return false, true
    end
    return true, false
  end
end
