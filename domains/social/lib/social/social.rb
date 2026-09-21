module Social
  class PublishPost
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :post_id, :author_id, :author, :body

    def initialize(post_id, author_id, author, body)
      @post_id = post_id
      @author_id = author_id
      @author = author
      @body = body
      valid = UUID.match?(@post_id) && UUID.match?(@author_id) && @author.is_a?(String) && @body.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
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

  class FollowUser
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :follower_id, :followee_id
    alias aggregate_id follower_id

    def initialize(follower_id, followee_id)
      @follower_id = follower_id
      @followee_id = followee_id
      valid = UUID.match?(@follower_id) && UUID.match?(@followee_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class UnfollowUser
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :follower_id, :followee_id
    alias aggregate_id follower_id

    def initialize(follower_id, followee_id)
      @follower_id = follower_id
      @followee_id = followee_id
      valid = UUID.match?(@follower_id) && UUID.match?(@followee_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
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

  class DeliverPostToTimeline
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :post_id, :recipient_id, :author, :body

    def initialize(post_id, recipient_id, author, body)
      @post_id = post_id
      @recipient_id = recipient_id
      @author = author
      @body = body
      valid = UUID.match?(@post_id) && UUID.match?(@recipient_id) && @author.is_a?(String) && @body.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end

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
