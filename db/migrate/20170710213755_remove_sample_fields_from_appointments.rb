class RemoveSampleFieldsFromAppointments < ActiveRecord::Migration[5.1]

	def up
		remove_column :appointments, :sample_requested
		remove_column :appointments, :sample_sent
	end

	def down
		if column_exists? :appointments, :sample_requested
			remove_column :appointments, :sample_requested
		end
		if column_exists? :appointments, :sample_sent
			remove_column :appointments, :sample_sent
		end
	end

end
