class AddXeroImportToStatus < ActiveRecord::Migration
  def change
  	add_column :statuses, :xero_import, :integer, limit: 1, index: true
  end
end
