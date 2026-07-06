require_relative "test_helper"

module Social
  class SocialTest < Test
    cover "Social*"

    def test_publish_post
      post_id = SecureRandom.uuid
      author_id = SecureRandom.uuid
      command_bus.call(
        PublishPost.new(post_id: post_id, author_id: author_id, author: "alice", body: "Hello, fediverse")
      )

      assert_event_published(
        PostPublished.new(
          data: { post_id: post_id, author_id: author_id, author: "alice", body: "Hello, fediverse" }
        )
      )
    end

    def test_follow_user
      follower = SecureRandom.uuid
      followee = SecureRandom.uuid
      command_bus.call(FollowUser.new(follower_id: follower, followee_id: followee))

      assert_event_published(UserFollowed.new(data: { follower_id: follower, followee_id: followee }))
    end

    def test_cannot_follow_the_same_user_twice
      follower = SecureRandom.uuid
      followee = SecureRandom.uuid
      command_bus.call(FollowUser.new(follower_id: follower, followee_id: followee))

      assert_raises(Following::AlreadyFollowing) do
        command_bus.call(FollowUser.new(follower_id: follower, followee_id: followee))
      end
    end

    def test_cannot_follow_yourself
      user = SecureRandom.uuid

      assert_raises(Following::CannotFollowSelf) do
        command_bus.call(FollowUser.new(follower_id: user, followee_id: user))
      end
    end

    def test_unfollow_user
      follower = SecureRandom.uuid
      followee = SecureRandom.uuid
      command_bus.call(FollowUser.new(follower_id: follower, followee_id: followee))
      command_bus.call(UnfollowUser.new(follower_id: follower, followee_id: followee))

      assert_event_published(UserUnfollowed.new(data: { follower_id: follower, followee_id: followee }))
    end

    def test_cannot_unfollow_a_user_you_do_not_follow
      follower = SecureRandom.uuid
      followee = SecureRandom.uuid

      assert_raises(Following::NotFollowing) do
        command_bus.call(UnfollowUser.new(follower_id: follower, followee_id: followee))
      end
    end

    def test_can_follow_again_after_unfollowing
      follower = SecureRandom.uuid
      followee = SecureRandom.uuid
      command_bus.call(FollowUser.new(follower_id: follower, followee_id: followee))
      command_bus.call(UnfollowUser.new(follower_id: follower, followee_id: followee))
      command_bus.call(FollowUser.new(follower_id: follower, followee_id: followee))

      assert_equal(2, event_store.read.of_type(UserFollowed).count)
    end

    def test_delivers_post_to_recipient_timeline
      command_bus.call(deliver_post_to_timeline)

      assert_event_published(
        PostDeliveredToTimeline.new(
          data: {
            post_id: post_id,
            recipient_id: recipient_id,
            author: "bob",
            body: "hi"
          }
        )
      )
    end

    def test_cannot_deliver_the_same_post_to_the_same_recipient_twice
      command_bus.call(deliver_post_to_timeline)

      assert_raises(Delivery::AlreadyDelivered) do
        command_bus.call(deliver_post_to_timeline)
      end
    end

    def test_delivers_the_same_post_to_different_recipients
      command_bus.call(deliver_post_to_timeline)

      command_bus.call(
        DeliverPostToTimeline.new(
          post_id: post_id,
          recipient_id: other_recipient_id,
          author: "bob",
          body: "hi"
        )
      )

      assert_equal(2, event_store.read.of_type(PostDeliveredToTimeline).count)
    end

    def test_delivers_different_posts_to_the_same_recipient
      command_bus.call(deliver_post_to_timeline)

      command_bus.call(
        DeliverPostToTimeline.new(
          post_id: other_post_id,
          recipient_id: recipient_id,
          author: "bob",
          body: "hi"
        )
      )

      assert_equal(2, event_store.read.of_type(PostDeliveredToTimeline).count)
    end

    def test_delivery_aggregate_id_uses_post_and_recipient
      assert_equal(
        "#{post_id}:#{recipient_id}",
        deliver_post_to_timeline.aggregate_id
      )
    end

    private

    def deliver_post_to_timeline
      DeliverPostToTimeline.new(
        post_id: post_id,
        recipient_id: recipient_id,
        author: "bob",
        body: "hi"
      )
    end

    def post_id
      @post_id ||= SecureRandom.uuid
    end

    def other_post_id
      @other_post_id ||= SecureRandom.uuid
    end

    def recipient_id
      @recipient_id ||= SecureRandom.uuid
    end

    def other_recipient_id
      @other_recipient_id ||= SecureRandom.uuid
    end

  end
end
