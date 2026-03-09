class DealsController < ApplicationController
  def index
    @deals = Deals.all
  end

  def show
    @deal = Deals.find_by_uid(params[:id])
    @pipeline = Pipelines.find_by_uid(@deal.pipeline_uid)
    @companies = Deals.companies_for(@deal.uid)
    @contacts = Deals.contacts_for(@deal.uid)
  end

  def new
    @pipelines = Pipelines.all
  end

  def create
    deal_id = SecureRandom.uuid
    deal_params = params.require(:deal).permit(:name, :pipeline_id, :value, :expected_close_date)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::CreateDeal.new(deal_id: deal_id, pipeline_id: deal_params[:pipeline_id], name: deal_params[:name]))
      command_bus.call(Crm::SetDealValue.new(deal_id: deal_id, value: deal_params[:value].to_i)) if deal_params[:value].present?
      command_bus.call(Crm::SetDealExpectedCloseDate.new(deal_id: deal_id, expected_close_date: deal_params[:expected_close_date])) if deal_params[:expected_close_date].present?
    end
    redirect_to deals_path
  end

  def edit
    @deal = Deals.find_by_uid(params[:id])
    @stages = Pipelines.stages_for(@deal.pipeline_uid)
    @all_companies = Companies.all
    @all_contacts = Contacts.all
  end

  def update
    deal_params = params.require(:deal).permit(:value, :expected_close_date, :stage, :company_id, :contact_id)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::SetDealValue.new(deal_id: params[:id], value: deal_params[:value].to_i)) if deal_params[:value].present?
      command_bus.call(Crm::SetDealExpectedCloseDate.new(deal_id: params[:id], expected_close_date: deal_params[:expected_close_date])) if deal_params[:expected_close_date].present?
      command_bus.call(Crm::MoveDealToStage.new(deal_id: params[:id], stage: deal_params[:stage])) if deal_params[:stage].present?
      command_bus.call(Crm::AssignCompanyToDeal.new(deal_id: params[:id], company_id: deal_params[:company_id])) if deal_params[:company_id].present?
      command_bus.call(Crm::AssignContactToDeal.new(deal_id: params[:id], contact_id: deal_params[:contact_id])) if deal_params[:contact_id].present?
    end
    redirect_to deal_path(params[:id])
  end
end
