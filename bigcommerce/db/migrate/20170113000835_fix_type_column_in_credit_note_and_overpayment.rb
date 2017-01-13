class FixTypeColumnInCreditNoteAndOverpayment < ActiveRecord::Migration
  def change
    remove_column :xero_credit_notes, :type
    add_column :xero_credit_notes, :note, :string, index: true

    remove_column :xero_overpayments, :type
    add_column :xero_overpayments, :note, :string, index: true

    remove_column :xero_overpayments, :xero_invoice_id
    remove_column :xero_overpayments, :invoice_number

  end
end
