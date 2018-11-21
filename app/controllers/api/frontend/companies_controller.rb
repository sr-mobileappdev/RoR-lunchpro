class Api::Frontend::CompaniesController < ApplicationController

  before_action :authenticate_user!

  def index
    render json: {
      companies: Company.all.map{|comp| {id: comp.id, name: comp.name}}
    }
  end

end
