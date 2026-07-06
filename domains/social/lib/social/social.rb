module Social
  class PublishPost < Infra::Command
    attribute :post_id, Infra::Types::UUID
    attribute :author_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class PostPublished < Infra::Event
    attribute :post_id, Infra::Types::UUID
    attribute :author_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class Post
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def publish(author_id, author, body)
      apply(PostPublished.new(data: { post_id: @id, author_id: author_id, author: author, body: body }))
    end

    on PostPublished do |event|
    end
  end

  class PublishPostHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Post, command.post_id) do |post|
        post.publish(command.author_id, command.author, command.body)
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

  class DeliverPostToTimeline < Infra::Command
    attribute :post_id, Infra::Types::UUID
    attribute :recipient_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String

    def aggregate_id
      "#{post_id}:#{recipient_id}"
    end
  end

  class PostDeliveredToTimeline < Infra::Event
    attribute :post_id, Infra::Types::UUID
    attribute :recipient_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class Delivery
    include AggregateRoot

    AlreadyDelivered = Class.new(StandardError)

    def initialize(_id)
    end

    def deliver(post_id, recipient_id, author, body)
      raise AlreadyDelivered if @delivered

      apply(
        PostDeliveredToTimeline.new(
          data: {
            post_id: post_id,
            recipient_id: recipient_id,
            author: author,
            body: body
          }
        )
      )
    end

    private

    on PostDeliveredToTimeline do |event|
      @delivered = true
    end
  end

  class DeliverPostToTimelineHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Delivery, command.aggregate_id) do |delivery|
        delivery.deliver(command.post_id, command.recipient_id, command.author, command.body)
      end
    end
  end
end
