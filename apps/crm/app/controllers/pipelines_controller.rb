class PipelinesController < ApplicationController
  def index
    @pipelines = Pipelines.all
  end

  def show
    @pipeline = Pipelines.find_by_uid(params[:id])
    @stages = Pipelines.stages_for(params[:id])
    @deals = Deals.for_pipeline(params[:id])
  end

  def new
  end

  def create
    pipeline_id = SecureRandom.uuid
    command_bus.call(Crm::CreatePipeline.new(pipeline_id: pipeline_id, name: params.require(:pipeline).permit(:name)[:name]))
    redirect_to pipelines_path
  end

  def add_stage
    command_bus.call(Crm::AddStageToPipeline.new(pipeline_id: params[:id], stage_name: params.require(:stage).permit(:name)[:name]))
    redirect_to pipeline_path(params[:id])
  end

  def remove_stage
    command_bus.call(Crm::RemoveStageFromPipeline.new(pipeline_id: params[:id], stage_name: params.require(:stage).permit(:name)[:name]))
    redirect_to pipeline_path(params[:id])
  end

  def move_deal
    command_bus.call(Crm::MoveDealToStage.new(deal_id: params[:deal_id], stage: params[:stage]))
    redirect_to pipeline_path(params[:id])
  end
end
