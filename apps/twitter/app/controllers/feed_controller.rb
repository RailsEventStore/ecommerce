class FeedController < ApplicationController
  def index
    @tweets = Feed.recent
  end
end
