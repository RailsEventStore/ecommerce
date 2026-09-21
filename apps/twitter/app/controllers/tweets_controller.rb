class TweetsController < ApplicationController
  before_action :require_sign_in

  def create
    command_bus.call(
      Social::PublishPost.new(
        SecureRandom.uuid,
        session[:account_id],
        current_handle,
        params[:body]
      )
    )
    redirect_to root_path
  end
end
