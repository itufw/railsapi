class Revision < ActiveRecord::Base

	def insert(notes = "")
		Time.zone = "GMT"
		time = Time.current

		Revision.create(next_update_time: time, notes: notes)
	end
end
