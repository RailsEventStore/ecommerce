require_relative "test_helper"

module ProductCatalog
  class CommandsTest < Test
    cover "ProductCatalog*"

    PRODUCT_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = NameProduct.new(PRODUCT_ID, "Async Remote")
      assert_equal(PRODUCT_ID, command.product_id)
      assert_equal("Async Remote", command.name)
    end

    def test_rejects_invalid_product_id
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_names
      [NameProduct, RequestProductNameChange, ModerateProductName].each do |command_class|
        assert_raises(Infra::Command::Invalid) { command_class.new(PRODUCT_ID, Object.new) }
      end
    end

    def test_accepts_string_subclass_names
      name = Class.new(String).new("Async Remote")
      [NameProduct, RequestProductNameChange, ModerateProductName].each do |command_class|
        assert_equal(name, command_class.new(PRODUCT_ID, name).name)
      end
    end

    private

    def constructors
      [
        ->(id) { RegisterProduct.new(id) },
        ->(id) { NameProduct.new(id, "Async Remote") },
        ->(id) { RequestProductNameChange.new(id, "Async Remote") },
        ->(id) { ModerateProductName.new(id, "Async Remote") }
      ]
    end
  end
end
