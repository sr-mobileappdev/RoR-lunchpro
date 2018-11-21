class SalesRepsSerializer < ActiveModel::Serializer

  def attributes(attrs, unknown_param = nil)
    data = super(attrs)

    fields = [:id, :first_name, :last_name, :company_id, :login_email, :is_activated, :drugs, :user_phone, :profile_image_url]
    if scope
      fields = scope.map &:to_sym
    end

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end

  def login_email
    (object.user) ? object.user.email : nil
  end

  def user_phone
    (object.user && object.user.primary_phone) ? object.user.primary_phone : nil
  end

  def is_activated
    object.is_activated?
  end

  def drugs
    object.drugs.map { |o|
      DrugsSerializer.new(o)
    }
  end

  def profile_image_url
    nil
  end

end
