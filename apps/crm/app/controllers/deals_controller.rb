class DealsController < ApplicationController
  def index
    @deals = Deals.all
  end

  def show
    @deal = Deals.find_by_uid(params[:id])
    @pipeline = Pipelines.find_by_uid(@deal.pipeline_uid)
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
  end

  def update
    deal_params = params.require(:deal).permit(:value, :expected_close_date, :stage)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::SetDealValue.new(deal_id: params[:id], value: deal_params[:value].to_i)) if deal_params[:value].present?
      command_bus.call(Crm::SetDealExpectedCloseDate.new(deal_id: params[:id], expected_close_date: deal_params[:expected_close_date])) if deal_params[:expected_close_date].present?
      command_bus.call(Crm::MoveDealToStage.new(deal_id: params[:id], stage: deal_params[:stage])) if deal_params[:stage].present?
    end
    redirect_to deal_path(params[:id])
  end
end
