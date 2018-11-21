class Forms::FrontendSalesRep < Forms::Form
  attr_writer :params
  attr_reader :errors

  attr_reader :sales_rep

  def initialize(user, params = {}, tab = nil)
    @params = params
    @errors = []
    @tab = tab
    @sales_rep = user
    @user = nil
    @phone = nil
    @email = nil
  end

  def valid?
    raise "Missing required parameters (:sales_rep)" unless @params
    @params = @params[:sales_rep] if @params[:sales_rep]
    # Validate Sales Rep
    @sales_rep ||= SalesRep.new()
    if @params[:specialties].present?
      @params[:specialties] = @params[:specialties].split(",")
    end
    @sales_rep.assign_attributes(@params)
  
    if !@sales_rep.company.present?
      if @params[:company_id].present?
        @company = Company.new(:name => @params[:company_id].humanize)
      end
    end
    if @params[:sales_rep_phones_attributes] && @params[:sales_rep_phones_attributes]['0'] && @params[:sales_rep_phones_attributes]['0'][:phone_number].present? && @sales_rep.user
      @user = @sales_rep.user
      @user.primary_phone = @params[:sales_rep_phones_attributes]['0'][:phone_number]
    end

    unless @sales_rep.valid?
      @errors += (@sales_rep.errors[:base] + @sales_rep.errors[:'user.base'])
    end
    return (@errors.count == 0)
  end

  def change_password?
    current_password = @params.delete(:current_password)
    if @sales_rep.valid_password?(current_password)

      if @sales_rep.update_attributes(@params)
      else
       @errors << @sales_rep.errors.full_messages
      end
    else
      @errors << "Current password does not match"
    end
    return (@errors.count == 0)
  end

  def set_company
    if @company.present? && @company.new_record?
      existing_comp = Company.select{|comp| comp.active? && comp.name.downcase == @company.name.downcase}.first
      if existing_comp
        @company = existing_comp
      else
        @company.assign_attributes(:created_by_id => @sales_rep.user.id, :status => 'active')
        @company.save!
      end
      @sales_rep.company = @company
      @sales_rep.save!
      true
    end
    true
  end

  def update_drugs(drugs = nil)
    drugs = drugs.split(',').map(&:to_i)
    current_drugs = @sales_rep.drugs.pluck(:drug_id)
    delete_drugs = current_drugs - drugs
    new_drugs = drugs - current_drugs
    @sales_rep.drugs.where(drug_id: delete_drugs).update_all(status: 'inactive')
    new_drugs.each do |drug|
      @sales_rep.drugs.create(drug_id: drug)
    end
  end
  def update_drugs(drugs = nil)
    drugs = drugs.split(',')
    current_drugs = @sales_rep.drugs.pluck(:drug_id)
    delete_drugs = current_drugs - drugs
    new_drugs = drugs - current_drugs
    @sales_rep.drugs.where(drug_id: delete_drugs).update_all(status: 'inactive')
    new_drugs.each do |drug|
      dr = Drug.where(:id => drug).first
      if dr
        @sales_rep.drugs.create(drug_id: dr.id)
      else
        @sales_rep.drugs.create(drug_id: Drug.create(:status => 'active', :created_by_id => @sales_rep.user.id, :brand => drug.humanize).id)
      end
    end
  end

  def save
    if valid? && persist! && set_company
      true
    else
      false
    end
  end

  def cancel

  end
private

  def persist!
    ActiveRecord::Base.transaction do
      if @tab == 'summary' && @sales_rep.save && (!@user || @user.save)
        return true
      elsif @tab != 'summary' && @sales_rep.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
