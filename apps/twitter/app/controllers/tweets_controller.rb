class TweetsController < ApplicationController
  before_action :require_sign_in

  def create
    command_bus.call(
      Social::PostTweet.new(
        tweet_id: SecureRandom.uuid,
        author: current_handle,
        body: params[:body]
      )
    )
    redirect_to root_path
  end

  private

  def require_sign_in
    redirect_to new_session_path unless current_handle
  end
end
