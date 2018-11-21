class InvitationMailer < SparkpostMailer
  default from: 'LunchPro <admin@lunchpro.com>'
  layout 'invitation_mailer'

  def invite(user, to_email, recipient)

    @from_address = "Lunchpro <admin@lunchpro.com>"

    set_content(user, recipient)
    #send_via_sparkpost(to_email, recipient.title, 'invite')
  end

private

  def set_content(user, recipient = nil)

    @recipient = recipient

    @template_content = nil
    if @recipient
      @template_content = Templates::UserTemplate.new(user).build(@recipient.email_content)
    end

  end

end
