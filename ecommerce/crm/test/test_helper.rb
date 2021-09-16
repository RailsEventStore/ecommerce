require "minitest/autorun"
require "mutant/minitest/coverage"

require "active_record"
ActiveRecord::Base.establish_connection("sqlite3::memory:")
ActiveRecord::Schema.verbose = false

require_relative "../lib/crm"

module Crm
  class Test < Infra::InMemoryTest
    def before_setup
      super
      @customer_repository = InMemoryCustomerRepository.new
      Configuration.new(cqrs, @customer_repository).call
      prepare_schema
    end

    attr_reader :customer_repository

    def prepare_schema
      ActiveRecord::Schema.define do
        create_table "customers", id: :uuid, force: :cascade do |t|
          t.string   "name"
          t.datetime "registered_at"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      end
    end
  end
end