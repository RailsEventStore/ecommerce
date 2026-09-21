require_relative "test_helper"

module Social
  class CommandsTest < Test
    cover "Social*"

    ID = "123e4567-e89b-42d3-a456-426614174000"
    OTHER_ID = "223e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = PublishPost.new(ID, OTHER_ID, "alice", "Hello")
      assert_equal(ID, command.post_id)
      assert_equal(OTHER_ID, command.author_id)
      assert_equal("alice", command.author)
      assert_equal("Hello", command.body)
      assert_equal("#{ID}:#{OTHER_ID}", DeliverPostToTimeline.new(ID, OTHER_ID, "alice", "Hello").aggregate_id)
    end

    def test_rejects_invalid_ids
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
      assert_raises(Infra::Command::Invalid) { PublishPost.new(ID, "bad", "alice", "Hello") }
      assert_raises(Infra::Command::Invalid) { FollowUser.new(ID, "bad") }
      assert_raises(Infra::Command::Invalid) { UnfollowUser.new(ID, "bad") }
      assert_raises(Infra::Command::Invalid) { DeliverPostToTimeline.new(ID, "bad", "alice", "Hello") }
    end

    def test_rejects_invalid_strings
      assert_raises(Infra::Command::Invalid) { PublishPost.new(ID, OTHER_ID, Object.new, "Hello") }
      assert_raises(Infra::Command::Invalid) { PublishPost.new(ID, OTHER_ID, "alice", Object.new) }
      assert_raises(Infra::Command::Invalid) { DeliverPostToTimeline.new(ID, OTHER_ID, Object.new, "Hello") }
      assert_raises(Infra::Command::Invalid) { DeliverPostToTimeline.new(ID, OTHER_ID, "alice", Object.new) }
    end

    def test_accepts_string_subclasses
      string = Class.new(String).new("value")
      assert_equal(string, PublishPost.new(ID, OTHER_ID, string, string).author)
      assert_equal(string, DeliverPostToTimeline.new(ID, OTHER_ID, string, string).body)
    end

    private

    def constructors
      [
        ->(id) { PublishPost.new(id, OTHER_ID, "alice", "Hello") },
        ->(id) { FollowUser.new(id, OTHER_ID) },
        ->(id) { UnfollowUser.new(id, OTHER_ID) },
        ->(id) { DeliverPostToTimeline.new(id, OTHER_ID, "alice", "Hello") }
      ]
    end
  end
end
