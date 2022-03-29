require_relative "test_helper"

module Infra
  class AggregateRootRepositoryTest < Infra::InMemoryTest
    cover "Infra::AggregateRootRepository*"

    class SomeEvent < RubyEventStore::Event
    end

    class DummyAggregateClass
      include AggregateRoot

      def initialize(id)
        @id = id
      end

      def do_something
        apply SomeEvent.new(data: {})
      end

      on SomeEvent do |_event|
      end
    end

    def test_with_aggregate_race_condition_occurrence
      repository = Infra::AggregateRootRepository.new(event_store)
      aggregate_id = SecureRandom.uuid

      concurrency_level = 2
      fail_occurred = false
      success_occurred = false
      wait_for_it = true

      threads = concurrency_level.times.map do |_|
        Thread.new do
          true while wait_for_it
          begin
            repository.with_aggregate(DummyAggregateClass, aggregate_id) do |dummy|
              dummy.do_something
            end
            success_occurred = true
          rescue RubyEventStore::WrongExpectedEventVersion
            fail_occurred = true
          end
        end
      end
      wait_for_it = false
      threads.each(&:join)

      assert_equal(fail_occurred, true)
      assert_equal(success_occurred, true)
    end

    def event_store
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new
      )
    end
  end
end
