class ApplicationsController < ApplicationController
  def index
    @applications = Applications.all
  end

  def new
    @application_id = SecureRandom.uuid
  end

  def create
    command_bus.call(
      Underwriting::SubmitApplication.new(
        params[:application_id],
        params[:coverage_amount].to_d
      )
    )
    redirect_to applications_path, notice: "Application submitted"
  end

  def evaluate_risk
    command_bus.call(
      Underwriting::EvaluateRisk.new(params[:id], params[:risk_class])
    )
    redirect_to applications_path, notice: "Risk evaluated"
  end

  def calculate_premium
    command_bus.call(Underwriting::CalculatePremium.new(params[:id]))
    redirect_to applications_path, notice: "Premium calculated"
  end

  def accept_offer
    command_bus.call(Underwriting::AcceptOffer.new(params[:id]))
    redirect_to applications_path, notice: "Offer accepted"
  end
end
