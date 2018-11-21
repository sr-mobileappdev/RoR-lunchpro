class Managers::SendPasswordResetManager
  attr_reader :errors

  def initialize()
    @errors = []
  end

  def mass_reset_password
=begin    users = User.where("encrypted_password like '$2a$10%'").select{|u| u.notifications.unsent.count == 0}

    users.each do |user|
      begin       
        Managers::NotificationManager.trigger_notifications([418], [user, user.entity])        
      rescue Exception => ex  
        next
      end
    end
=end    
  end

private



end
