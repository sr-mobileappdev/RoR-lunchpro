class OfficeDeviceLog < ApplicationRecord
	belongs_to :offices
	
	enum connection_type: {wifi:1, cell:2}
	
end
