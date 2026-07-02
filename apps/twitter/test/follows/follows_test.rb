require_relative "../test_helper"

module Follows
  class FollowsTest < InMemoryRESTestCase
    cover "Follows*"

    def test_records_the_users_a_follower_follows
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      carol = SecureRandom.uuid
      follow(alice, bob)
      follow(alice, carol)

      assert_equal([bob, carol].sort, Follows.followees_of(alice).sort)
    end

    def test_scopes_followees_to_the_follower
      alice = SecureRandom.uuid
      other = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)
      follow(other, bob)

      assert_equal([bob], Follows.followees_of(alice))
    end

    def test_removes_only_the_unfollowed_followee
      alice = SecureRandom.uuid
      bob = SecureRandom.uuid
      carol = SecureRandom.uuid
      follow(alice, bob)
      follow(alice, carol)

      unfollow(alice, bob)

      assert_equal([carol], Follows.followees_of(alice))
    end

    def test_removes_only_for_the_acting_follower
      alice = SecureRandom.uuid
      other = SecureRandom.uuid
      bob = SecureRandom.uuid
      follow(alice, bob)
      follow(other, bob)

      unfollow(alice, bob)

      assert_equal([bob], Follows.followees_of(other))
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
  end
end
