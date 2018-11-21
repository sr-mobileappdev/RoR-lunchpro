class Admin::NotificationEventsController < AdminTableController
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate]
  before_action :set_collection_record


  def set_record
    @record = NotificationEvent.find(params[:id])
  end

  def set_collection_record
    @collection = NotificationEventRecipient.where(notification_event_id: @record)
  end

  # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = NotificationEvent.none

    if params[:scope]

    else
      @manager = Managers::AdminTableManager.new(NotificationEvent, ['category_cid','status__light','internal_summary'])
      @records = @manager.paged(@page, @per_page, "category_cid")
    end

  end

  def get_table_path(params)
    admin_notification_events_path(params)
  end
  # --

  def activate
    @record.active!
    @collection.each do |i|
      i.active!
    end
    flash[:notice] = "Notification has been activated."
    render :json => {success: true, redirect: @record.id }
  end

  def deactivate
    @record.inactive!
    @collection.each do |i|
      i.inactive!
    end
    flash[:alert] = "Notification has been deactivated."
    render :json => {success: true, redirect: @record.id }
  end

  def index

  end

  def show

  end

end
