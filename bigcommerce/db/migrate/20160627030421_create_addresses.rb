class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|


      t.integer :customer_id, unsigned: true, index: true

      t.text :firstname, :lastname, :company, limit: 255

      t.text :street_1
      t.text :street_2

      t.text :city, :state, :postcode, :country, :phone, :email, limit: 255

      t.timestamps null: false

    end
  end
end
