require_relative "../test_helper"

class TimelineDeliveryProcessTest < ProcessTest
  cover "TimelineDeliveryProcess*"

  def setup
    super
    @process = TimelineDeliveryProcess.new(event_store, command_bus)
  end

  def test_delivers_a_new_post_to_its_author
    process(::Social::PostPublished.new(data: { post_id: post_id, author_id: bob, author: "bob", body: "hi" }))

    assert_all_commands(
      Social::DeliverPostToTimeline.new(
        post_id: post_id,
        recipient_id: bob,
        author: "bob",
        body: "hi"
      )
    )
  end

  def test_delivers_a_new_post_to_each_follower_and_the_author
    process(::Social::UserFollowed.new(data: { follower_id: alice, followee_id: bob }))
    process(::Social::UserFollowed.new(data: { follower_id: carol, followee_id: bob }))
    process(::Social::PostPublished.new(data: { post_id: post_id, author_id: bob, author: "bob", body: "hi" }))

    assert_equal(
      [alice, carol, bob],
      command_bus.all_received.map(&:recipient_id)
    )
  end

  def test_delivers_to_followers_only_of_the_posting_author
    process(::Social::UserFollowed.new(data: { follower_id: alice, followee_id: other_author }))
    process(::Social::PostPublished.new(data: { post_id: post_id, author_id: bob, author: "bob", body: "hi" }))

    assert_equal([bob], command_bus.all_received.map(&:recipient_id))
  end

  def test_does_not_deliver_to_unfollowed_users
    process(::Social::UserFollowed.new(data: { follower_id: alice, followee_id: bob }))
    process(::Social::UserUnfollowed.new(data: { follower_id: alice, followee_id: bob }))
    process(::Social::PostPublished.new(data: { post_id: post_id, author_id: bob, author: "bob", body: "hi" }))

    assert_equal([bob], command_bus.all_received.map(&:recipient_id))
  end

  def test_does_not_deliver_old_posts_to_new_followers
    process(::Social::PostPublished.new(data: { post_id: post_id, author_id: bob, author: "bob", body: "hi" }))
    command_bus.clear_all_received
    process(::Social::UserFollowed.new(data: { follower_id: alice, followee_id: bob }))

    assert_no_command
  end

  def test_does_not_redeliver_old_posts_when_a_user_unfollows
    process(::Social::UserFollowed.new(data: { follower_id: alice, followee_id: bob }))
    process(::Social::UserFollowed.new(data: { follower_id: carol, followee_id: bob }))
    process(::Social::PostPublished.new(data: { post_id: post_id, author_id: bob, author: "bob", body: "hi" }))
    command_bus.clear_all_received
    process(::Social::UserUnfollowed.new(data: { follower_id: alice, followee_id: bob }))

    assert_no_command
  end

  private

  def process(event)
    event_store.publish(event)
    @process.call(event)
  end

  def alice
    @alice ||= SecureRandom.uuid
  end

  def carol
    @carol ||= SecureRandom.uuid
  end

  def bob
    @bob ||= SecureRandom.uuid
  end

  def other_author
    @other_author ||= SecureRandom.uuid
  end

  def post_id
    @post_id ||= SecureRandom.uuid
  end
end
