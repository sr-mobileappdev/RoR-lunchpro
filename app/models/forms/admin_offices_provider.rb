class Forms::AdminOfficesProvider < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :offices_provider
  attr_reader :provider
  attr_reader :office

  def initialize(provider_or_office, user, params = {}, existing_provider = nil, set_availability = false)
    @current_user = user
    @office = (provider_or_office && provider_or_office.kind_of?(Office)) ? provider_or_office : nil
    @params = params
    @errors = []

    if existing_provider
      @provider = existing_provider
      @offices_provider = nil
    end

    @set_availability = true if set_availability == "1"
    #create array of specialties from selectize
    if @params[:provider][:specialties].present?
      @params[:provider][:specialties] = @params[:provider][:specialties].split(",")
    end
  end

  def valid?

    # IF we're only editing provider, no need for offices_provider
    unless @provider && @provider.id
      raise "Missing required parameters (:offices_provider)" unless @params[:offices_provider]
    end

    raise "Missing required parameters (:provider)" unless @params[:provider]

    # Validate Provider

    @provider ||= Provider.new()
    @provider.assign_attributes(@params[:provider])
    if @params[:diet_restrictions] && @params[:diet_restrictions].kind_of?(ActionController::Parameters)
      @params[:diet_restrictions].each do |key, val|
        @provider.diet_restrictions.delete(DietRestriction.find(key))
        if val == "1"
          @provider.diet_restrictions << DietRestriction.find(key)
        end
      end
    end

    # IF we're only editing provider, don't pass through offices_provider
    unless @provider && @provider.id
      base_params = {office_id: @office.id, provider: @provider} if @office
      @offices_provider ||= OfficesProvider.new(base_params)
      @offices_provider.assign_attributes(@params[:offices_provider])

      unless @offices_provider.valid?
        @errors += @offices_provider.errors.full_messages
      end
    end

    unless @provider.valid?
      @errors += @provider.errors.full_messages
    end

    return (@errors.count == 0)
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
    if valid? && persist!
      true
    else
      false
    end
  end

private


  def persist!
    ActiveRecord::Base.transaction do
      if @provider.save
        unless @offices_provider
          if @set_availability
            if set_availability
              return true
            else
              raise ActiveRecord::Rollback
            end
          else
            raise ActiveRecord::Rollback
          end
        end
        @offices_provider.provider = @provider
        if @offices_provider.save && set_availability
          return true
        else
          raise ActiveRecord::Rollback
        end
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
