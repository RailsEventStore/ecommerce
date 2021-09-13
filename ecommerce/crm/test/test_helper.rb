require "minitest/autorun"
require "mutant/minitest/coverage"

require "active_record"
ActiveRecord::Base.establish_connection("sqlite3::memory:")
ActiveRecord::Schema.verbose = false

require_relative "../lib/crm"

module Crm
  class Test < Minitest::Test
    include Infra::TestPlumbing.with(
      event_store: ->{ Infra::EventStore.in_memory },
      command_bus: ->{ Infra::CommandBus.new }
    )

    def before_setup
      super
      Configuration.new(Infra::Cqrs.new(event_store, command_bus)).call
      prepare_schema
    end

    def prepare_schema
      ActiveRecord::Schema.define do
        create_table "customers", id: :uuid, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      end
    end
  end
end