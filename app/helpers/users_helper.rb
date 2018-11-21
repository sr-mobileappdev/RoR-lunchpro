module UsersHelper

  def user_invite_status_flag(invite_status = nil)
    if invite_status && invite_status == "Accepted"
      "<span class='lp__text_positive'>#{invite_status}</span>".html_safe
    elsif invite_status && invite_status == "Invite Pending"
      "<span class='lp__text_pending'>#{invite_status}</span>".html_safe
    elsif invite_status && invite_status == "No Invite Sent"
      "<span class='lp__text_minor'>#{invite_status}</span>".html_safe
    end
  end

  def user_confirmation_status_flag(confirmation_status = nil)
    if confirmation_status && confirmation_status == "Confirmed"
      "<span class='lp__text_positive'>#{confirmation_status}</span>".html_safe
    elsif confirmation_status && confirmation_status == "Confirmation Pending"
      "<span class='lp__text_pending'>#{confirmation_status}</span>".html_safe
    elsif confirmation_status && confirmation_status == "No Confirmation Sent"
      "<span class='lp__text_minor'>#{confirmation_status}</span>".html_safe
    end
  end

  def sales_rep_lunchpro_status(rep)
    return nil if !rep
    rep.is_lp? ? "LunchPro" : "--"
  end
end
