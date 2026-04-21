module Customers
  class AccountsController < ApplicationController
    def new
      @customer_id = params[:customer_id]
    end

    def create
      account_id = SecureRandom.uuid
      customer_id = params[:customer_id]
      ActiveRecord::Base.transaction do
        command_bus.(Authentication::RegisterAccount.new(account_id: account_id))
        command_bus.(Authentication::ConnectAccountToClient.new(account_id: account_id, client_id: customer_id))
        command_bus.(Authentication::SetLogin.new(account_id: account_id, login: params[:login]))
        command_bus.(Authentication::SetPasswordHash.new(account_id: account_id, password_hash: Digest::SHA256.hexdigest(params[:password])))
      end
      redirect_to customers_path, notice: "Account was successfully created"
    end
  end
end
