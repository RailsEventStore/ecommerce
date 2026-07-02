class TweetsController < ApplicationController
  before_action :require_sign_in

  def create
    command_bus.call(
      Social::PostTweet.new(
        tweet_id: SecureRandom.uuid,
        author_id: session[:account_id],
        author: current_handle,
        body: params[:body]
      )
    )
    redirect_to root_path
  end
end
