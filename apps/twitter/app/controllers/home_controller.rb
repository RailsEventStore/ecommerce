class HomeController < ApplicationController
  before_action :require_sign_in

  def index
    @entries = HomeTimeline.for(session[:account_id])
  end
end
