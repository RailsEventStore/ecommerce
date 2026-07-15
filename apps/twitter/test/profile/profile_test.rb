require_relative "../test_helper"

module Profile
  class ProfileTest < InMemoryRESTestCase
    cover "Profile*"

    def test_returns_an_authors_posts_newest_first
      alice = SecureRandom.uuid
      publish_post(alice, "alice", "first")
      publish_post(alice, "alice", "second")

      assert_equal(["second", "first"], Profile.posts_of(alice).map(&:body))
    end

    def test_scopes_posts_to_the_author
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      publish_post(alice, "alice", "alice post")
      publish_post(bob, "bob", "bob post")

      assert_equal(["alice post"], Profile.posts_of(alice).map(&:body))
    end

    def test_stores_the_author_handle
      alice = SecureRandom.uuid
      publish_post(alice, "alice", "hi")

      assert_equal("alice", Profile.posts_of(alice).first.author)
    end

    private

    def publish_post(author_id, author, body)
      event_store.publish(
        ::Social::PostPublished.new(
          data: { post_id: SecureRandom.uuid, author_id: author_id, author: author, body: body }
        )
      )
    end
  end
end
