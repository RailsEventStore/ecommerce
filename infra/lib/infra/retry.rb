module Infra
  module Retry
    def with_retry
      yield
    rescue RubyEventStore::WrongExpectedEventVersion
      yield
    end
  end
end
