class Managers::SearchManager
  attr_writer :model
  attr_writer :search_term
  attr_writer :relation
  attr_writer :options
  DEFAULT_PER_PAGE = 50

  def initialize(object, search_term, options = {})
    @model = object || ""
    @search_term = search_term
    @relation = object
    @options = options
  end

  def paged_results(page = 1, per_page = DEFAULT_PER_PAGE)
    results.page(page).per(per_page)
  end

  def results
    case @model.to_s
      when "Office"
        office_results
      when "SalesRep"
        sales_rep_results
      when "Company"
        company_results
      when "Drug"
        drug_results
      else
        raise "Searching against a model not set up in search_manager"
    end
  end

  def results_for_rep(sales_rep, exclude_own_offices = true)
    # Limit results to those viewable by a specific sales rep, excluding their own offices if desired
    my_office_ids = []
    if exclude_own_offices
      offices_sales_reps = sales_rep.offices_sales_reps.active

      offices_sales_reps.each do |office|
        my_office_ids << office.office.id
      end
    end
    #office_results.where.not(id: my_office_ids).where.not(:activated_at => nil)
    office_results.where.not(id: my_office_ids, internal: false).active
  end

  def results_for_rep_my_offices(sales_rep)
    my_office_ids = []
    offices_sales_reps = sales_rep.offices_sales_reps.active

    offices_sales_reps.each do |office|
      my_office_ids << office.office.id
    end
    #office_results.where(id: my_office_ids).where.not(:activated_at => nil)
    office_results.where(id: my_office_ids, :status => 'active').where.not(:activated_at => nil)
  end

  def results_for_rep_my_providers(sales_rep)
    my_office_ids = []
    offices_sales_reps = sales_rep.offices_sales_reps.active

    offices_sales_reps.each do |office|
      my_office_ids << office.office.id if office.office.activated?
    end
    my_providers_results(my_office_ids)
  end

  def company_results
    ar = @model.arel_table
    @model.where(ar[:name].matches("%#{@search_term}%")).where(:status => 'active')
  end

  def drug_results
    ar = @model.arel_table
    @model.where(ar[:brand].matches("%#{@search_term}%").or(ar[:generic_name].matches("%#{@search_term}%"))).where(:status => 'active')
  end

  def office_results
    @provider = Provider
    provider_ar = @provider.arel_table
    ar = @model.arel_table
    office_ids = @provider.joins(:offices_providers)
                  .where(provider_ar[:first_name].matches("%#{@search_term}%")
                    .or(provider_ar[:last_name].matches("%#{@search_term}%")))
                  .where(:status => 'active').pluck(:office_id)

    @model.where(ar[:name].matches("%#{@search_term}%")
      .or(ar[:postal_code].matches("%#{@search_term}%"))
      .or(ar[:state].matches("%#{@search_term}%"))
      .or(ar[:address_line1].matches("%#{@search_term}%"))
      .or(ar[:city].matches("%#{@search_term}%"))
      .or(ar[:id].in(office_ids)))
    .where(:status => 'active')
  end

  def my_providers_results(my_office_ids = [])
    @office = Office
    office_ar = @office.arel_table
    ar = @model.arel_table
    office_ids = @office.where(office_ar[:name].matches("%#{@search_term}%")
                  .or(office_ar[:postal_code].matches("%#{@search_term}%"))
                  .or(office_ar[:state].matches("%#{@search_term}%"))
                  .or(office_ar[:address_line1].matches("%#{@search_term}%"))
                  .or(office_ar[:city].matches("%#{@search_term}%")))
                .where(:status => 'active', id: my_office_ids).pluck(:id)

    results = @model.joins(:offices_providers)
    .where(OfficesProvider.arel_table[:office_id].in(office_ids)
      .or(ar[:first_name].matches("%#{@search_term}%")
      .or(ar[:last_name].matches("%#{@search_term}%"))))
    .where(:status => 'active')

    results.select{|prov| prov.office.activated?}
  end

  def om_sales_rep_results(office_id, rep_ids)
    @sales_rep = SalesRep
    rep_ar = @sales_rep.arel_table
    company_ar = Company.arel_table
    offices_sales_rep_ar = OfficesSalesRep.arel_table
    drugs_sales_reps_ar = DrugsSalesRep.arel_table
    drugs_ar = Drug.arel_table

    ar = @model.arel_table



    reps = @model.where(rep_ar[:id].in(rep_ids)).where(         #Reps that are active and tied to the office
      rep_ar[:first_name].matches("%#{@search_term}%")
      .or(rep_ar[:last_name].matches("%#{@search_term}%"))      #reps with First or last name like search term
      .or(rep_ar[:id].in(rep_ar.project(rep_ar[:id]).join(company_ar) 
        .on(rep_ar[:company_id].eq(company_ar[:id]))
        .where(company_ar[:name].matches("%#{@search_term}%")))  #or Reps with their company name like search term
      )
      .or(rep_ar[:id].eq(rep_ar.project(rep_ar[:id]).join(offices_sales_rep_ar)
        .on(rep_ar[:id].eq(offices_sales_rep_ar[:sales_rep_id]))
        .where(offices_sales_rep_ar[:office_id].eq(office_id)
          .and(offices_sales_rep_ar[:status].eq("active"))
          .and(offices_sales_rep_ar[:office_notes].matches("%#{@search_term}%"))      #or reps with the office's notes about the rep like search term
        )
      ))
      .or(rep_ar[:id].in(rep_ar.project(rep_ar[:id]).join(drugs_sales_reps_ar)
        .on(rep_ar[:id].eq(drugs_sales_reps_ar[:sales_rep_id]))
        .where(drugs_sales_reps_ar[:status].eq("active")
        .and(drugs_sales_reps_ar[:drug_id].in(drugs_ar.project(drugs_ar[:id])
          .where(drugs_ar[:brand].matches("%#{@search_term}%")
            .or(drugs_ar[:generic_name].matches("%#{@search_term}%"))))))))       #or reps with drugs that have a brand or generic name like search term
    )

    reps

  end

  def sales_rep_results
    terms = []
    if @search_term.include?(" ")
      terms = @search_term.split(" ")
    else
      terms = [@search_term, @search_term]
    end
    ar = @model.arel_table
    relation = @model.where(ar[:first_name].matches("%#{terms[0]}%").or(ar[:last_name].matches("%#{terms[1]}%"))).where(:status => 'active')


    # -- Handle various potential option limitations
    if @options && @options[:office_id]
      # Limit to only those sales reps at a given office
      relation = relation.joins(:offices_sales_reps).where(offices_sales_reps: {office_id: @options[:office_id]})
    else
      relation = relation
    end

    relation
  end

end
