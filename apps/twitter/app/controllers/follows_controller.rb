class FollowsController < ApplicationController
  before_action :require_sign_in

  def index
    @followees = Follows.followees_of(session[:account_id]).map { |id| Accounts.handle_for(id) }
  end

  def create
    command_bus.call(
      Social::FollowUser.new(
        follower_id: session[:account_id],
        followee_id: Accounts.id_for(params[:handle])
      )
    )
    redirect_to follows_path
  end

  def destroy
    command_bus.call(
      Social::UnfollowUser.new(
        follower_id: session[:account_id],
        followee_id: Accounts.id_for(params[:id])
      )
    )
    redirect_to follows_path
  end
end
