class Templates::SalesRepTemplate < Templates::BaseTemplate
  attr_reader :sales_rep

  def initialize(obj = nil)
    @object_type = obj.class
    @sales_rep = obj
  end

  def tags
    return [] if !@sales_rep
    {
      full_name: 'display_name',
      first_name: 'first_name',
      last_name: 'last_name',
      company_name: 'company_name',
      book_appointment_url: 'book_appointment_url',
      next_weeks_appointments_table: 'next_weeks_appointments_table',
      email_address: 'email_address',
      phone_number: 'phone_number',
      view_partner_request_url: 'view_partner_request_url',
      is_lp?: 'is_lp?',
      is_non_lp?: 'is_non_lp?',
      login_url: 'login_url',
      register_url: 'register_url'
    }
  end
  def __login_url
    UrlHelpers.new_user_session_url
  end

  def __register_url
    UrlHelpers.new_user_registration_url
  end

  def __is_lp?
    @sales_rep.is_lp?
  end

  def __is_non_lp?
    !@sales_rep.is_lp?
  end

  def __email_address
    @sales_rep.email("business")
  end

  def __phone_number
    ApplicationController.helpers.format_phone_number_string(@sales_rep.phone_record("business")) || "Phone Unavailable"
  end
  def __book_appointment_url
     UrlHelpers.new_rep_appointment_url
  end

  def __view_partner_request_url
     UrlHelpers.rep_profile_index_url(tab: 'partner')
  end

  def __next_weeks_appointments_table
    begin
      ac = ActionController::Base.new()
      ah = ApplicationController.helpers
      appointments = @sales_rep.next_weeks_appointments
      ##should style table in email content and render <trs> in partial
      table = ac.render_to_string(partial: 'shared/notification_partials/next_weeks_appointments', 
        :layout => false, locals:{appointments: appointments, ah: ah}, :formats => [:html])
      table.html_safe
    rescue Exception => ex 
      Rollbar.error(ex)
    end
  end

end
