module Social
  class PostTweet < Infra::Command
    attribute :tweet_id, Infra::Types::UUID
    attribute :author_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class TweetPosted < Infra::Event
    attribute :tweet_id, Infra::Types::UUID
    attribute :author_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class Tweet
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def post(author_id, author, body)
      apply(TweetPosted.new(data: { tweet_id: @id, author_id: author_id, author: author, body: body }))
    end

    on TweetPosted do |event|
    end
  end

  class PostTweetHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Tweet, command.tweet_id) do |tweet|
        tweet.post(command.author_id, command.author, command.body)
      end
    end
  end

  class FollowUser < Infra::Command
    attribute :follower_id, Infra::Types::UUID
    attribute :followee_id, Infra::Types::UUID
    alias aggregate_id follower_id
  end

  class UnfollowUser < Infra::Command
    attribute :follower_id, Infra::Types::UUID
    attribute :followee_id, Infra::Types::UUID
    alias aggregate_id follower_id
  end

  class UserFollowed < Infra::Event
    attribute :follower_id, Infra::Types::UUID
    attribute :followee_id, Infra::Types::UUID
  end

  class UserUnfollowed < Infra::Event
    attribute :follower_id, Infra::Types::UUID
    attribute :followee_id, Infra::Types::UUID
  end

  class Following
    include AggregateRoot

    AlreadyFollowing = Class.new(StandardError)
    NotFollowing = Class.new(StandardError)
    CannotFollowSelf = Class.new(StandardError)

    def initialize(id)
      @id = id
      @followees = []
    end

    def follow(followee_id)
      raise CannotFollowSelf if followee_id == @id
      raise AlreadyFollowing if @followees.include?(followee_id)

      apply(UserFollowed.new(data: { follower_id: @id, followee_id: followee_id }))
    end

    def unfollow(followee_id)
      raise NotFollowing unless @followees.include?(followee_id)

      apply(UserUnfollowed.new(data: { follower_id: @id, followee_id: followee_id }))
    end

    on UserFollowed do |event|
      @followees << event.data.fetch(:followee_id)
    end

    on UserUnfollowed do |event|
      @followees.delete(event.data.fetch(:followee_id))
    end
  end

  class FollowUserHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Following, command.follower_id) do |following|
        following.follow(command.followee_id)
      end
    end
  end

  class UnfollowUserHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Following, command.follower_id) do |following|
        following.unfollow(command.followee_id)
      end
    end
  end
end
