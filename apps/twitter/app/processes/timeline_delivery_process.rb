class TimelineDeliveryProcess
  include RubyEventStore::ProcessManager.with_state { ProcessState }

  subscribes_to(
    Social::UserFollowed,
    Social::UserUnfollowed,
    Social::PostPublished
  )

  private

  def act
    recipients.each { |recipient_id| deliver_post_to(recipient_id) } if state.post
  end

  def recipients
    state.followers + [state.post.data.fetch(:author_id)]
  end

  def apply(event)
    case event
    when Social::UserFollowed
      state.with(followers: state.followers | [event.data.fetch(:follower_id)], post: nil)
    when Social::UserUnfollowed
      state.with(followers: state.followers - [event.data.fetch(:follower_id)], post: nil)
    when Social::PostPublished
      state.with(post: event)
    end
  end

  def fetch_id(event)
    case event
    when Social::UserFollowed, Social::UserUnfollowed
      event.data.fetch(:followee_id)
    when Social::PostPublished
      event.data.fetch(:author_id)
    end
  end

  def deliver_post_to(recipient_id)
    command_bus.call(
      Social::DeliverPostToTimeline.new(
        post_id: state.post.data.fetch(:post_id),
        recipient_id: recipient_id,
        author: state.post.data.fetch(:author),
        body: state.post.data.fetch(:body)
      )
    )
  end

  ProcessState = Data.define(:followers, :post) do
    def initialize(followers: [], post: nil)
      super(followers: followers.freeze, post: post)
    end
  end
end
