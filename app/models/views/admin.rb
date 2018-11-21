class Views::Admin
  # Decoration / View methods for display of various admin details

  def self.for_user(user)
    raise "Admin view is applicable to space_admin users only" unless user.space_admin?
    new(user)
  end

  def initialize(user)
    @user = user
  end

  # - The Good Stuff
  def recent_notifications
    @recent_notifications ||= @user.notifications.visible
  end

end
