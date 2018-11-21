class Managers::BankAccountManager

  attr_reader :errors, :stripe_account

  def initialize(restaurant, bank_account=nil, user)
    @errors = Array.new
    @restaurant = restaurant
    @bank_account = bank_account
    @user = user
    set_stripe_account
  end

  def authorize
    raise "No bank account provided" unless @bank_account.present?
    #Not sure what kind of authorizations are necessary for creating an account and/or bank account for established account
  end

  def create_stripe_account
    return false if @restaurant.stripe_account.present?
    account = Stripe::Account.create({
      type: 'custom'
    }) #Must update account with other information after creation
    update_stripe_account(account)
    @restaurant.stripe_account = account.id
    if @restaurant.save
      true
    else
      account.delete #deletes the stripe customer that was just created
      false
    end

  rescue => e
    handle_errors(e)
  end

  def update_stripe_account(account)
    account = Stripe::Account.retrieve(account.id)
    account.business_name = @restaurant.name
    account.support_phone = @restaurant.phone
    account.save
  end

  def create_stripe_bank_account(stripe_token=nil, params, status)
    stripe_token ||= ('' if Rails.env.development?)
    return false unless stripe_token.present?
    status = "active" if !status
    if stripe_account_active?
      @bank_account = BankAccount.create(restaurant_id: @restaurant.id, stripe_identifier: stripe_account.id, last_four: bank_account.last4)
      if return_bank_account_id
        return @bank_account.id
      else
        true
      end
    elsif stripe_account_deleted?
      false
    else
      create_stripe_account ? @stripe_account.sources.create(source: stripe_token) : false #I think account.sources would give the bank accounts associated with the stripe account
    end

  end

  def delete_stripe_bank_account
    if stripe_account_active
      temp = stripe_account.sources.retrieve(@bank_account.stripe_identifier).delete()
      true
    else
      @errors << "A Stripe account does not exist for this business"
      false
    end
  rescue => e
    handle_errors(e)
  end

  # Helper Methods -------------------------------------------------------------------------------------

  def stripe_account_active?
    @stripe_account.try(:object).present?
  end

  def stripe_account_deleted?
    @stripe_account.try(:deleted).present?
  end

  def bank_account_deleted?
    return nil unless @bank_account.try(:stripe_identifier)
    BankAccount.stripe_object(@bank_account.stripe_identifier).try(:deleted).present?
  end

  private

    def handle_errors(e)
      @errors << e.message
    end

    def set_stripe_account
      if @restaurant.stripe_account.blank?
        @restaurant.stripe_account = nil
        create_stripe_account
      end

      @stripe_account = Stripe::Account.retrieve(@restaurant.stripe_account)

      unless stripe_account_active?
        raise "Managers::BankAccountManager.set_stripe_account Failed to set stripe account."
      end

    rescue => e
      handle_errors(e)
    end

end #Managers::BankAccountManager
