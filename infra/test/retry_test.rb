require_relative "test_helper"

module Infra
  class RetryTest < Minitest::Test
    cover "Infra::Retry"

    include Infra::Retry

    def test_no_error
      result = with_retry { true }
      assert result
    end

    def test_retries_once
      attempts = 0
      with_retry do
        attempts += 1
        raise RubyEventStore::WrongExpectedEventVersion if attempts == 1
      end

      assert_equal 2, attempts
    end

    def test_fails_after_two_attempts
      attempts = 0
      assert_raises RubyEventStore::WrongExpectedEventVersion do
        with_retry do
          attempts += 1
          raise RubyEventStore::WrongExpectedEventVersion
        end
      end

      assert_equal 2, attempts
    end
  end
end
