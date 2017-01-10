class Note < ActiveRecord::Base
  belongs_to :customers
  belongs_to :staffs


  def create_note(n, insert)

		text = remove_apostrophe(n.text)
		priority = remove_apostrophe(n.priority)
#   status = remove_apostrophe(n.status)
		due_date = remove_apostrophe(n.due_date)
		staff_id = remove_apostrophe(n.staff_id)
		customer_id = map_date(n.customer_id)

		sql = note = ""

		if insert == 1
			unallocated_staff_id = 34
			note =  "('#{text}', '#{priority}', '#{due_date}',\
			'#{staff_id}', '#{customer_id}')"

			sql = "INSERT INTO notes(text, priority, due_date, staff_id, customer_id) VALUES #{note}"
		else

			sql = "UPDATE notes SET text = '#{text}', priority = '#{priority}', due_date = '#{due_date}',\
			staff_id = '#{staff_id}', customer_id = '#{customer_id}' WHERE id = '#{n.id}'"
		end
        ActiveRecord::Base.connection.execute(sql)
	end


  def self.valid
    where('due_date <= CURDATE()')
  end

end
