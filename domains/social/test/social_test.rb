require_relative "test_helper"

module Social
  class SocialTest < Test
    cover "Social*"

    def test_post_tweet
      tweet_id = SecureRandom.uuid
      author_id = SecureRandom.uuid
      command_bus.call(
        PostTweet.new(tweet_id: tweet_id, author_id: author_id, author: "alice", body: "Hello, fediverse")
      )

      assert_event_published(
        TweetPosted.new(
          data: { tweet_id: tweet_id, author_id: author_id, author: "alice", body: "Hello, fediverse" }
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
  end
end
