class Import < ApplicationRecord
  include LunchproRecord

  mount_uploader :import_file, FileUploader
  belongs_to :uploaded_by, class_name: 'User'


	#list of col heads to check against each col iteration
	def self.menu_item_import_headers
		[
			{csv_header: 'menu_item', db_header: nil}, 
			{csv_header: 'sub_menu_item', db_header: nil}, 
			{csv_header: 'sub_menu_item_option', db_header: nil},
  		{csv_header: 'name', db_header: 'name'},  
  		{csv_header: 'description', db_header: 'description'}, 
  		{csv_header: 'price_cents', db_header: 'retail_price_cents'},
			{csv_header: 'category', db_header: 'category'} ,
			{csv_header: 'people_served', db_header: 'people_served'}, 
			{csv_header: 'sub_options_qty_allowed', db_header: 'qty_allowed'}, 
			{csv_header: 'lunchpack', db_header: 'lunchpack'}
		]
	end

	#list of accepted yes values
	def self.yes_values
		['y','yes','1','true','t']
	end	


end
