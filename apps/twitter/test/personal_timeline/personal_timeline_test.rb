require_relative "../test_helper"

module PersonalTimeline
  class PersonalTimelineTest < InMemoryRESTestCase
    cover "PersonalTimeline*"

    def test_fans_out_a_tweet_to_each_follower
      alice = SecureRandom.uuid
      carol = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)
      follow(carol, bob)

      publish_post(bob, "bob", "hi")

      assert_equal(["hi"], PersonalTimeline.for(alice).map(&:body))
      assert_equal(["hi"], PersonalTimeline.for(carol).map(&:body))
    end

    def test_fans_out_only_to_followers_of_the_author
      alice = SecureRandom.uuid
      dave = SecureRandom.uuid
      bob = SecureRandom.uuid
      eve = SecureRandom.uuid
      follow(alice, bob)
      follow(dave, eve)

      publish_post(bob, "bob", "hi")

      assert_equal(["hi"], PersonalTimeline.for(alice).map(&:body))
      assert_equal([], PersonalTimeline.for(dave).to_a)
    end

    def test_stores_author_handle_and_body
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)

      publish_post(bob, "bob", "hi")

      entry = PersonalTimeline.for(alice).first
      assert_equal("bob", entry.author)
      assert_equal("hi", entry.body)
    end

    def test_shows_newest_tweets_first
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)

      publish_post(bob, "bob", "first")
      publish_post(bob, "bob", "second")

      assert_equal(["second", "first"], PersonalTimeline.for(alice).map(&:body))
    end

    def test_unfollow_only_removes_that_edge_for_that_follower
      alice = SecureRandom.uuid
      carol = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)
      follow(carol, bob)

      unfollow(alice, bob)
      publish_post(bob, "bob", "hi")

      assert_equal([], PersonalTimeline.for(alice).to_a)
      assert_equal(["hi"], PersonalTimeline.for(carol).map(&:body))
    end

    def test_unfollow_only_removes_the_named_followee
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      eve = SecureRandom.uuid
      follow(alice, bob)
      follow(alice, eve)

      unfollow(alice, bob)
      publish_post(eve, "eve", "still here")

      assert_equal(["still here"], PersonalTimeline.for(alice).map(&:body))
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

    def publish_post(author_id, author, body)
      event_store.publish(
        ::Social::PostPublished.new(
          data: { post_id: SecureRandom.uuid, author_id: author_id, author: author, body: body }
        )
      )
    end
  end
end
