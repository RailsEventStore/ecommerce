class SessionsController < ApplicationController
  def new
  end

  def create
    account_id = Accounts.authenticate(params[:handle], params[:password])
    if account_id
      session[:account_id] = account_id
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:account_id)
    redirect_to root_path
  end
end
