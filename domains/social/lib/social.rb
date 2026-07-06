require 'infra'
require_relative 'social/social'

module Social
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(PublishPost, PublishPostHandler.new(event_store))
      command_bus.register(FollowUser, FollowUserHandler.new(event_store))
      command_bus.register(UnfollowUser, UnfollowUserHandler.new(event_store))
    end
  end
end
