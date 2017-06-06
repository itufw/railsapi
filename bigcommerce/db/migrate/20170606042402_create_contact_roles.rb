class CreateContactRoles < ActiveRecord::Migration
  def change
    create_table :contact_roles do |t|
      t.string :role, :staff_role
      t.integer :contact_role_sort
      t.timestamps null: false
    end
  end
end
