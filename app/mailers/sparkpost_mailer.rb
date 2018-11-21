class SparkpostMailer < ApplicationMailer

  def from_address
    @from_address || "LunchPro <notices@lunchpro.com>"
  end
  
  def auto_bcc_list
  	if ENV["STAGING_NOTIFICATIONS"].present? && ENV["STAGING_NOTIFICATIONS"] == "true"
  		return ['admin@collectivepoint.com']
  	else
  		return ['customerservice@lunchpro.com']
  	end  	
  end

  def send_via_sparkpost(to_email, subject, template = nil, notification = nil)
    subject = "" if !subject
    sparkpost_config = {
      track_opens: true,
      track_clicks: false,
      campaign_id: "Test Campaign",
      transactional: true,
      api_key: ENV['SPARKPOST_KEY']
    }

    #if Final receipt notification, create pdf and attach
    if notification && notification.notification_event && 
      notification.notification_event.category_cid.to_i == 402 && notification.related_objects["order_id"].present?

      @order = Order.find(notification.related_objects["order_id"])
      if @order
        ah = ApplicationController.helpers
        mail.attachments["Order_#{@order.order_number}.pdf"] =  WickedPdf.new.pdf_from_string(
        render_to_string(partial: 'shared/pdf/rep_om_order_detail', :layout => 'pdf', 
          locals:{order: @order, ah: ah}, :formats => [:html]))
      end
    end
    if notification.user
      manager = Managers::IcsManager.new(notification.related_objects, notification.user, notification.notification_event.category_cid)
      cal = manager.create_cal 

    # else if non lp sales rep without user
    elsif notification.related_objects["non_lp_sales_rep_id"].present?
      manager = Managers::IcsManager.new(notification.related_objects, SalesRep.find(notification.related_objects["non_lp_sales_rep_id"]), notification.notification_event.category_cid)
      cal = manager.create_cal 
    else
      cal = nil
    end
      subject = notification.subject(subject)
    if template
      if cal
        subject = manager.subject
        mail.attachments['calendar_event.ics'] = { mime_type: 'text/calendar', content: cal} 
        mail(to: to_email, from: from_address, subject: subject, template_name: template, bcc: auto_bcc_list)
      else
        subject = notification.title if !subject
        mail(to: to_email, from: from_address, subject: subject, template_name: template, bcc: auto_bcc_list)
      end
    else
      subject = notification.title if !subject
      mail(to: to_email, from: from_address, subject: subject, bcc: auto_bcc_list)
    end
  
  end

  #used for sending out the weekly payout report
  def send_weekly_payout_report(start_date = nil, end_date = nil)
    #if start and end date is provided, use that as date range
    if start_date && end_date

    #else beginning of week to current date
    else
      start_date = ((Date.today) + (Date.today.wday - 6) * -1) - 7
      end_date = Date.today.to_date        
    end
    subject = "Weekly Payout for #{start_date} to #{end_date}"
    sparkpost_config = {
      track_opens: true,
      track_clicks: false,
      campaign_id: "Test Campaign",
      transactional: true,
      api_key: ENV['SPARKPOST_KEY']
    }
    from_address = ENV['SPARKPOST_DEFAULT_FROM']
    to_emails = ENV['WEEKLY_PAYOUT_RECIPIENT']

    #grab csv data
    man = Managers::CsvManager.new
    csv_data = man.generate_restaurant_weekly_payout(nil, start_date, end_date, true)
    filename = "weekly_payout_report_#{start_date}-to-#{end_date}"
    attachments[filename] = {mime_type: 'text/csv', content: csv_data}
  
    mail(to: to_emails, from: from_address, subject: subject, template_name: 'admin', body: "Attached is the weekly payout report for #{start_date} to #{end_date}", bcc: auto_bcc_list)
  end
end
