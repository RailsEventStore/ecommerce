require "minitest/autorun"
require "mutant/minitest/coverage"

require "active_record"
ActiveRecord::Base.establish_connection("sqlite3::memory:")
ActiveRecord::Schema.verbose = false

require_relative "../lib/ordering"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../pricing/lib/pricing"
require_relative "../../crm/lib/crm"

module Ordering
  class Test < Infra::InMemoryTest
    def before_setup
      super
      prepare_schema
      @number_generator = FakeNumberGenerator.new
      Configuration.new(cqrs, event_store, -> { @number_generator }).call

      ProductCatalog::Configuration.new(cqrs).call
      Pricing::Configuration.new(cqrs, event_store).call
      Crm::Configuration.new(cqrs, Crm::InMemoryCustomerRepository.new).call
    end

    def prepare_schema
      ActiveRecord::Schema.define do
        create_table "products", id: :uuid, force: :cascade do |t|
          t.string "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.decimal "price", precision: 8, scale: 2
          t.integer "stock_level"
        end
      end
    end
  end
end
