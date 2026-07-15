class ProfilesController < ApplicationController
  def show
    account_id = Accounts.id_for(params[:handle])
    return head(:not_found) unless account_id

    @handle = params[:handle]
    @posts = Profile.posts_of(account_id)
  end
end
