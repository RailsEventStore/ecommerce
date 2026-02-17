class CompaniesController < ApplicationController
  def index
    @companies = Companies.all
  end

  def show
    @company = Companies.find_by_uid(params[:id])
  end

  def new
  end

  def create
    company_id = SecureRandom.uuid
    company_params = params.require(:company).permit(:name, :linkedin_url)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::RegisterCompany.new(company_id: company_id, name: company_params[:name]))
      command_bus.call(Crm::SetCompanyLinkedinUrl.new(company_id: company_id, linkedin_url: company_params[:linkedin_url])) if company_params[:linkedin_url].present?
    end
    redirect_to companies_path
  end

  def edit
    @company = Companies.find_by_uid(params[:id])
  end

  def update
    company_params = params.require(:company).permit(:linkedin_url)

    command_bus.call(Crm::SetCompanyLinkedinUrl.new(company_id: params[:id], linkedin_url: company_params[:linkedin_url])) if company_params[:linkedin_url].present?
    redirect_to company_path(params[:id])
  end
end
