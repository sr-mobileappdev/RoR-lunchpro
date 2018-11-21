class Forms::OfficeManagers::OmProvider
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :provider

  def initialize(user, params = {}, existing_provider = nil, office = nil, set_availability = false)
    @current_user = user
    @params = params
    @errors = []
    @office = office
    @new_record = false
    @provider = existing_provider

    #create array of specialties from selectize
    if @params[:specialties].present?
      @params[:specialties] = @params[:specialties].split(",")
    end
    @set_availability = true if set_availability == "1"
  end

  def valid?
    # Validate provider
    #@provider ||= provider.new()

    @provider = @provider || Provider.new()
    @new_record = @provider.new_record?

    if @params[:provider_availabilities_attributes].present? && !@set_availability
      return (@errors.count == 0) unless validate_provider_availabilities
    end

    params = @params.dup
    params.delete(:provider_availabilities_attributes) if @new_record || @set_availability
    @provider.assign_attributes(params)

    unless @provider.valid?
      @errors += @provider.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def create_offices_provider_record
    if @new_record
      @provider.offices_providers.create(:office_id => @office.id)
      params = @params.dup
      params.delete(:provider_availabilities_attributes) if @set_availability
      @provider.assign_attributes(params)
      if @provider.valid? && @provider.save
        true
      else
        @errors << @provider.errors.full_messages
        false
      end
    else
      true
    end
  end


  #select all avail params that arent marked for destruction.
  #compare avails starts_at..ends_at time range to the other avails that are not marked for destruction
  #and are for the same day_of_week
  #throw validation error if avails timezone overlaps with another avail
  def validate_provider_availabilities
    avails = @params[:provider_availabilities_attributes]
    avails.select{|key, avail| avail["_destroy"] != 'true' && avail["status"] != 'deleted'}.each do |key, avail|
      next if !avail[:starts_at].present? || !avail[:ends_at].present?
      avail = avail.to_hash
      timerange = Tod::TimeOfDay(avail['starts_at'])..Tod::TimeOfDay(avail['ends_at'])
      if avails.select{|key, av| av["day_of_week"] == avail["day_of_week"] && av["_destroy"] != 'true' && av["status"] != 'deleted' && (timerange).cover?(Tod::TimeOfDay(av.to_hash['starts_at']) ||
        (timerange).cover?(Tod::TimeOfDay(av.to_hash['ends_at'])))}.to_hash.count > 1
        @errors << "You cannot provide overlapping availabilities."
        return false
      end
    end
  end

  def set_availability
    return true if !@set_availability || !@office
    begin
      @provider.provider_availabilities.update_all(:status => 'deleted')
      @office.week_schedule.each do |day|
        @provider.provider_availabilities << ProviderAvailability.new(:day_of_week => day[:day_of_week], :starts_at => day[:starts_at], :ends_at => day[:ends_at])
      end
      true
    rescue Exception => ex
      Rollbar.error(ex)
      false
    end
  end

  def save
    if persist!
      true
    else
      false
    end
  end


private

  def persist!
    ActiveRecord::Base.transaction do
      if @provider.save && create_offices_provider_record && set_availability
        
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
