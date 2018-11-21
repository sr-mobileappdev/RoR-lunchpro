class Api::V1::OfficeDeviceLogsController < ApiController
	skip_before_action :check_user_space, only: [:create]
	def create
		@office_device_log = OfficeDeviceLog.create(create_params)
		render json: { success:true, log: @office_device_log } and return
	end

	private
	def create_params
		return params.permit(:office_id, :app_version, :timestamp, :office_name, :device_name, :device_os, :device_id, :connection_type)
	end
end