class FeedController < ApplicationController
  def index
    @tweets = PublicFeed.recent
  end
end
