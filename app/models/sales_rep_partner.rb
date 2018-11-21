class SalesRepPartner < ApplicationRecord
	# Plan A:
	# A sucessful 'partnership' involves two records. The initiating sales_rep (sales_rep_id) invites another rep (partner_id). This creates 1 record in a pending state.
		# If the partner_id accepts the invite, the first record changes it's state to accepted and a second record is created with an accepted status.
		# At a later point, either partner may destroy the partnership and both records are changed to deleted.
	# In a different scenario the initiating sales_rep's invite is rejected, only the one initial record exists and it remains in the 'rejected' state indefinitely.
	# In a rejected scenario, a partner who rejected the initial offer may send a subsequent invite (second record) and if if accepted,
		# both records change state to accepted.
	# If we provide functionality to 'cancel' an invite by the initiating sales_rep, the cancel action will put the pending record in a deleted state.
	# The second record on an accepted partnership provides a direct look up for performance instead of always having to do a two-column lookup.

  attr_accessor :partner_email
  belongs_to :sales_rep
	belongs_to :partner, class_name: 'SalesRep'
	belongs_to :created_by, class_name: 'User'

	enum status: {pending: Constants::STATUS_PENDING,
								accepted: Constants::STATUS_COMPLETED,
								rejected: Constants::STATUS_REJECTED, # ignored
								deleted: Constants::STATUS_DELETED
	}

	validates_presence_of :sales_rep, :status


  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  before_save :flag_for_notifications
  after_save :trigger_notifications

  def flag_for_notifications
    @notify_partner_request = false
    if (self.new_record? && self.status == 'pending') || (['inactive', 'deleted', 'rejected'].include?(self.status_was) && self.status == 'pending')
      @notify_partner_request = true
    end
  end

  def partner_email=(email = nil)
    return if !email
    rep = SalesRep.select{|rep| rep.user && rep.user.active? && rep.active? && rep.user.email.downcase == email.downcase && 
      rep.user.space == 'space_sales_rep'}.first
    if rep
      self.write_attribute(:partner_id, rep.id)
    end
  end
  def trigger_notifications
    begin
      if @notify_partner_request
        Managers::NotificationManager.trigger_notifications([213], [self.partner, self])
      end
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end

  def create_validations
    if self.sales_rep_id == self.partner_id
      self.errors.add(:base, "You cannot send a partner request to yourself!")
      return
    end
    if sales_rep && (sales_rep.sales_rep_partners.accepted.count + SalesRepPartner.where(:status => [Constants::STATUS_COMPLETED], :partner_id => sales_rep.id).count) > Constants::SALES_REP_PARTNER_LIMIT
      self.errors.add(:base, "You may only have up to #{Constants::SALES_REP_PARTNER_LIMIT} active partnerships at one time.")
      return
    end
    if sales_rep && (sales_rep.sales_rep_partners.select{|p| p.accepted? || p.pending?}.pluck(:partner_id)).include?(partner_id)
      self.errors.add(:base, "A partner request has already been sent to this user")
      return
    end
  end

  def update_validations
  	if SalesRepPartner.statuses[self.status] == Constants::STATUS_COMPLETED
    	if partner && (partner.sales_rep_partners.accepted.count + SalesRepPartner.where(:status => [Constants::STATUS_COMPLETED], :partner_id => partner.id).count) > Constants::SALES_REP_PARTNER_LIMIT
      		self.errors.add(:base, "You may only have up to #{Constants::SALES_REP_PARTNER_LIMIT} active partnerships at one time.")
      		return
    	end
    	if sales_rep && (sales_rep.sales_rep_partners.accepted.count + SalesRepPartner.where(:status => [Constants::STATUS_COMPLETED], :partner_id => sales_rep.id).count) > Constants::SALES_REP_PARTNER_LIMIT
      		self.errors.add(:base, "The agent you are trying to partner with has already partnered with #{Constants::SALES_REP_PARTNER_LIMIT} other agents.")
      		return
    	end
    end
  end


end
