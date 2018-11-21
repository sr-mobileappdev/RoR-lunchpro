class ProvidersSerializer < ActiveModel::Serializer

  def attributes(attrs, unknown_param = nil)
    data = super(attrs)

    fields = [:id, :first_name, :last_name, :specialties, :title, :office_name, :office_id, :provider_availabilities, :provider_exclude_dates]
    if scope
      fields = scope.map &:to_sym
    end

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end
  
  def provider_exclude_dates
  	object.provider_exclude_dates.as_json(:except => ["starts_at","ends_at"], :methods => ["starts_at_date","ends_at_date"])
  end
  
  def provider_availabilities
  	object.provider_availabilities
  end

end
