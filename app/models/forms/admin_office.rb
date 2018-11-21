class Forms::AdminOffice < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :office

  def initialize(user, params = {}, existing_office = nil)
    @current_user = user
    @params = params
    @errors = []

    @office = existing_office

  end

  def valid?
    raise "Missing required parameters (:office)" unless @params[:office]

    # Validate office
    @office ||= Office.new()
    @office.assign_attributes(@params[:office])

    if @params[:office][:diet_restrictions_offices_attributes]
      @office.diet_restrictions_offices.delete_all #clear temporary restrictions when building view

      @params[:office][:diet_restrictions_offices_attributes].each_pair do |attr, key|      
        if key[:diet_restriction_id].to_i > 0
          @office.diet_restrictions_offices << DietRestrictionsOffice.new(:diet_restriction_id => key[:temp_restriction_id].to_i, :staff_count => key[:staff_count])
        end
      end
    end

    unless @office.valid?
      @errors += @office.errors.full_messages
    end
    return (@errors.count == 0)
  end


  #used to activate office and trigger notifs
  def activate
    ActiveRecord::Base.transaction do
      begin
        previously_active = (@office.deactivated_at != nil) ? true : false
        @office.update_attributes(activated_at: Time.now, status: "active", activated_by_id: @current_user.id)
        # Trigger Notification 401 - New Office Live (and send to all related sales reps as well)
        #   Do not re-notify if the office was previously active
        unless previously_active
          Managers::NotificationManager.trigger_notifications([401], [@office], {related_sales_reps: @office.active_reps(true)}) # @record = sales rep
        end

        @office.sales_reps.each do |rep|
          #if rep has any appointments with this office
          if rep.appointments.where(:office_id => @office.id).any?
            Managers::NotificationManager.trigger_notifications([217], [@office, rep]) # @record = sales rep
          #else
          else
            Managers::NotificationManager.trigger_notifications([216], [@office, rep]) # @record = sales rep
          end
        end

        #queue up all notifs that are tied to this office
        Notification.where("notified_at is null and related_objects::json->>'office_id' = ?", "#{@office.id}").update_all(:queued_at => Time.now)


        true
      rescue Exception => ex
        Rollbar.error(ex)
        @errors << ex
        false
      end
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
      if @office.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
