class ClaimsController < ApplicationController
  def index
    @claims = ClaimList.all
  end

  def new
    @claim_id = SecureRandom.uuid
    @policies = PolicyList.all
  end

  def create
    command_bus.call(
      Claims::ReportLoss.new(
        params[:claim_id],
        params[:policy_id],
        params[:description]
      )
    )
    redirect_to claims_path, notice: "Loss reported"
  end

  def assess
    command_bus.call(
      Claims::AssessLoss.new(params[:id], params[:amount].to_d)
    )
    redirect_to claims_path, notice: "Loss assessed"
  end
end
