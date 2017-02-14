class AddCcBccAccountTable < ActiveRecord::Migration
  def change

    add_column :account_emails, :cc, :string

    add_column :account_emails, :bcc, :string

    add_column :account_emails, :content_second, :text

  end
end
