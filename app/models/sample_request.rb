class SampleRequest < ApplicationRecord
	belongs_to :appointment
	belongs_to :drug

	validates_presence_of :appointment, :drug
end
