require_relative "../test_helper"

module HomeTimeline
  class HomeTimelineTest < InMemoryRESTestCase
    cover "HomeTimeline*"

    def test_fans_out_a_tweet_to_each_follower
      alice = SecureRandom.uuid
      carol = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)
      follow(carol, bob)

      post_tweet(bob, "bob", "hi")

      assert_equal(["hi"], HomeTimeline.for(alice).map(&:body))
      assert_equal(["hi"], HomeTimeline.for(carol).map(&:body))
    end

    def test_fans_out_only_to_followers_of_the_author
      alice = SecureRandom.uuid
      dave = SecureRandom.uuid
      bob = SecureRandom.uuid
      eve = SecureRandom.uuid
      follow(alice, bob)
      follow(dave, eve)

      post_tweet(bob, "bob", "hi")

      assert_equal(["hi"], HomeTimeline.for(alice).map(&:body))
      assert_equal([], HomeTimeline.for(dave).to_a)
    end

    def test_stores_author_handle_and_body
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)

      post_tweet(bob, "bob", "hi")

      entry = HomeTimeline.for(alice).first
      assert_equal("bob", entry.author)
      assert_equal("hi", entry.body)
    end

    def test_shows_newest_tweets_first
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)

      post_tweet(bob, "bob", "first")
      post_tweet(bob, "bob", "second")

      assert_equal(["second", "first"], HomeTimeline.for(alice).map(&:body))
    end

    def test_unfollow_only_removes_that_edge_for_that_follower
      alice = SecureRandom.uuid
      carol = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)
      follow(carol, bob)

      unfollow(alice, bob)
      post_tweet(bob, "bob", "hi")

      assert_equal([], HomeTimeline.for(alice).to_a)
      assert_equal(["hi"], HomeTimeline.for(carol).map(&:body))
    end

    def test_unfollow_only_removes_the_named_followee
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      eve = SecureRandom.uuid
      follow(alice, bob)
      follow(alice, eve)

      unfollow(alice, bob)
      post_tweet(eve, "eve", "still here")

      assert_equal(["still here"], HomeTimeline.for(alice).map(&:body))
    end

    private

    def follow(follower_id, followee_id)
      event_store.publish(
        ::Social::UserFollowed.new(data: { follower_id: follower_id, followee_id: followee_id })
      )
    end

    def unfollow(follower_id, followee_id)
      event_store.publish(
        ::Social::UserUnfollowed.new(data: { follower_id: follower_id, followee_id: followee_id })
      )
    end

    def post_tweet(author_id, author, body)
      event_store.publish(
        ::Social::TweetPosted.new(
          data: { tweet_id: SecureRandom.uuid, author_id: author_id, author: author, body: body }
        )
      )
    end
  end
end
