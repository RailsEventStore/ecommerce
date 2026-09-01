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
      Claims::ReportDamage.new(
        claim_id: params[:claim_id],
        policy_id: params[:policy_id],
        description: params[:description]
      )
    )
    redirect_to claims_path, notice: "Damage reported"
  end

  def evaluate
    command_bus.call(
      Claims::EvaluateDamage.new(claim_id: params[:id], amount: params[:amount].to_d)
    )
    redirect_to claims_path, notice: "Damage evaluated"
  end
end
