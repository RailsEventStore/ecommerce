module Social
  class PostTweet < Infra::Command
    attribute :tweet_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class TweetPosted < Infra::Event
    attribute :tweet_id, Infra::Types::UUID
    attribute :author, Infra::Types::String
    attribute :body, Infra::Types::String
  end

  class Tweet
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def post(author, body)
      apply(TweetPosted.new(data: { tweet_id: @id, author: author, body: body }))
    end

    on TweetPosted do |event|
    end
  end

  class PostTweetHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Tweet, command.tweet_id) do |tweet|
        tweet.post(command.author, command.body)
      end
    end
  end
end
