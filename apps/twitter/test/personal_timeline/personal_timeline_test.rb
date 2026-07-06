require_relative "../test_helper"

module PersonalTimeline
  class PersonalTimelineTest < InMemoryRESTestCase
    cover "PersonalTimeline*"

    def test_adds_delivered_post_to_recipient_timeline
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid

      deliver_post(alice, bob, "bob", "hi")

      assert_equal(["hi"], PersonalTimeline.for(alice).map(&:body))
    end

    def test_adds_delivered_post_only_to_the_recipient_timeline
      alice = SecureRandom.uuid
      dave = SecureRandom.uuid
      bob = SecureRandom.uuid

      deliver_post(alice, bob, "bob", "hi")

      assert_equal(["hi"], PersonalTimeline.for(alice).map(&:body))
      assert_equal([], PersonalTimeline.for(dave).to_a)
    end

    def test_stores_author_handle_and_body
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid

      deliver_post(alice, bob, "bob", "hi")

      entry = PersonalTimeline.for(alice).first
      assert_equal("bob", entry.author)
      assert_equal("hi", entry.body)
    end

    def test_shows_newest_tweets_first
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid

      deliver_post(alice, bob, "bob", "first")
      deliver_post(alice, bob, "bob", "second")

      assert_equal(["second", "first"], PersonalTimeline.for(alice).map(&:body))
    end

    private

    def deliver_post(recipient_id, author_id, author, body)
      event_store.publish(
        ::Social::PostDeliveredToTimeline.new(
          data: {
            post_id: SecureRandom.uuid,
            recipient_id: recipient_id,
            author: author,
            body: body
          }
        )
      )
    end
  end
end
