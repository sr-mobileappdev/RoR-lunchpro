class Admin::SearchesController < AdminController

  skip_before_action :authenticate_admin_user!

  def quick

    template = nil
    case params[:search_type]
      when "office"
        template = quick_offices_results(params[:search_term])
      when "sales_rep"
        template = quick_sales_reps_results(params[:search_term], params[:office_id])
      when "user"
        template = quick_users_results(params[:search_term])
      when "restaurant"
        template = quick_restaurants_results(params[:search_term])
      when "company"
        template = quick_companies_results(params[:search_term])
      when "drug"
        template = quick_drugs_results(params[:search_term])
    end

    if template
      render json: { html: (render_to_string :partial => template, :layout => false, :formats => [:html]) }
    else
      render json: { success: false, general_error: "Missing quick search template", errors: []}, status: 500
    end

  end

  def quick_offices_results(term)
    @results = Managers::SearchManager.new(Office, term).results
    template = 'admin/shared/quicksearch/offices'
  end

  def quick_sales_reps_results(term, limit_to_office_id = nil)
    @results = Managers::SearchManager.new(SalesRep, term, {office_id: limit_to_office_id}).results
    template = 'admin/shared/quicksearch/sales_reps'
  end

  def quick_users_results(term)

  end

  def quick_restaurants_results(term)

  end

  def quick_companies_results(term)
    @results = Managers::SearchManager.new(Company, term).results
    template = 'admin/shared/quicksearch/companies'
  end

  def quick_drugs_results(term)
    @results = Managers::SearchManager.new(Drug, term).results
    template = 'admin/shared/quicksearch/drugs'
  end

end
