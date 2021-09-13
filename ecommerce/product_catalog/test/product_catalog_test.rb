require_relative "test_helper"

module ProductCatalog
  class ProductCatalogTest < Minitest::Test
    include Infra::TestPlumbing.with(
      event_store: ->{ RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) },
      command_bus: ->{ Arkency::CommandBus.new }
    )

    def before_setup
      result = super
      ProductCatalog::Configuration.new(Infra::Cqrs.new(event_store, command_bus)).call
      prepare_schema
      result
    end

    def prepare_schema
      ActiveRecord::Schema.define do
        create_table "products", id: :uuid, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.decimal  "price", precision: 8, scale: 2
          t.integer  "stock_level"
        end
      end
    end

    def run_command(command)
      command_bus.call(command)
    end

    cover "ProductCatalog*"

    def test_product_should_get_registered
      uid = SecureRandom.uuid
      register_product(uid, fake_name)
      refute_nil(product_registered = Product.find(uid))
      assert_equal(product_registered.name, fake_name)
    end

    def test_should_not_allow_for_double_registration
      uid = SecureRandom.uuid
      assert_raises(Product::AlreadyRegistered) do
        2.times { register_product(uid, fake_name) }
      end
    end

    private

    def register_product(uid, name)
      run_command(RegisterProduct.new(product_id: uid, name: name))
    end

    def fake_name
      "Fake name"
    end
  end
end

