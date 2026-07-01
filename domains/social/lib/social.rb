require 'infra'
require_relative 'social/social'

module Social
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(PostTweet, PostTweetHandler.new(event_store))
    end
  end
end
