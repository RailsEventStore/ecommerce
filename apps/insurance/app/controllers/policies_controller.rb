class PoliciesController < ApplicationController
  def index
    @policies = PolicyList.all
  end

  def pay_premium
    ActiveRecord::Base.transaction do
      command_bus.call(Payments::AuthorizePayment.new(params[:id]))
      command_bus.call(Payments::CapturePayment.new(params[:id]))
    end
    redirect_to policies_path, notice: "Premium paid"
  end

  def terminate
    command_bus.call(Policies::TerminatePolicy.new(params[:id]))
    redirect_to policies_path, notice: "Policy terminated"
  end
end
