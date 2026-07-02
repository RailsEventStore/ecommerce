class RegistrationsController < ApplicationController
  def new
  end

  def create
    account_id = SecureRandom.uuid
    ActiveRecord::Base.transaction do
      command_bus.call(Authentication::RegisterAccount.new(account_id: account_id))
      command_bus.call(Authentication::SetLogin.new(account_id: account_id, login: params[:handle]))
      command_bus.call(
        Authentication::SetPasswordHash.new(
          account_id: account_id,
          password_hash: BCrypt::Password.create(params[:password])
        )
      )
    end
    session[:account_id] = account_id
    redirect_to root_path
  end
end
