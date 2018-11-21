class Managers::TimeManager
  attr_writer :time
  attr_writer :office_id
  attr_writer :timezone

  #expects time to be a string "06:00:00" or a Tod:TimeOfDay object
  def initialize(time, date = nil, office_id = nil, timezone = nil)
    return nil if !time || !time.present?  
    if time.kind_of?(Tod::TimeOfDay)
      @time = time
    else
      @time = Tod::TimeOfDay(time)
    end    
    @office = Office.find(office_id) if office_id
    @date = date || Date.current
    if @office
      @timezone = @office.timezone || Time.zone.name
    else
      @timezone = timezone || Time.zone
    end
  end

  def time_converted_to_utc
    return unless @time && @timezone
    (@date + @time.to_i.seconds).asctime.in_time_zone(@timezone).utc.strftime('%H:%M:%S')
   # time = (@params[:appointment][:appointment_on].to_date + Tod::TimeOfDay(@params[:appointment][:starts_at]).to_i.seconds).asctime.in_time_zone("UTC").in_time_zone(office.timezone)
  end

end
