class Office::OfficeExcludeDatesController < ApplicationOfficesController

  before_action :set_office

  def set_office
    @office = current_user.user_office.office
  end

  def index
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/exclude_date', :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  #used when a user 'excludes' an open appt slot
  def create
    unless params[:date].present? && params[:office_id].present?
      raise "Must provide date and office id to exclude an appointment slot."
    end
    office_exclude_date = OfficeExcludeDate.new(:office_id => params[:office_id], :starts_at => params[:date], :ends_at => params[:date])

    unless office_exclude_date.save
      render :json => {success: false, general_error: "Unable to update office exclusion date due to the following errors or notices:", errors: @office.errors.full_messages}, status: 500
      return
    end
    redirect_to current_office_calendars_path

  end

  def destroy

  end

end
