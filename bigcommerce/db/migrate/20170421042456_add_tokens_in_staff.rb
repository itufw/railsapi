class AddTokensInStaff < ActiveRecord::Migration
  def change
    add_column :staffs, :access_token, :string
    add_column :staffs, :refresh_token, :string

  end
end
