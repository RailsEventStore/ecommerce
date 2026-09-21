require_relative "test_helper"

module Taxes
  class CommandsTest < Test
    cover "Taxes*"

    ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = SetVatRate.new(ID, "20")
      assert_equal(ID, command.product_id)
      assert_equal("20", command.vat_rate_code)
      assert_equal("20", RemoveAvailableVatRate.new("20").vat_rate_code)
    end

    def test_coerces_vat_rate_hash
      command = AddAvailableVatRate.new(ID, { code: "20", rate: 20 })
      assert_equal(ID, command.available_vat_rate_id)
      assert_equal(Infra::Types::VatRate.new(code: "20", rate: 20), command.vat_rate)
    end

    def test_rejects_invalid_ids
      ["not-a-uuid", Object.new, "123e4567-e89b-12d3-a456-426614174000", "123e4567-e89b-42d3-7456-426614174000"].each do |id|
        assert_raises(Infra::Command::Invalid) { SetVatRate.new(id, "20") }
        assert_raises(Infra::Command::Invalid) { AddAvailableVatRate.new(id, { code: "20", rate: 20 }) }
      end
    end

    def test_rejects_invalid_codes_and_vat_rates
      assert_raises(Infra::Command::Invalid) { SetVatRate.new(ID, Object.new) }
      assert_raises(Infra::Command::Invalid) { RemoveAvailableVatRate.new(Object.new) }
      assert_raises(Infra::Command::Invalid) { AddAvailableVatRate.new(ID, Object.new) }
    end

    def test_accepts_string_subclass_codes
      code = Class.new(String).new("20")
      assert_equal(code, SetVatRate.new(ID, code).vat_rate_code)
      assert_equal(code, RemoveAvailableVatRate.new(code).vat_rate_code)
    end
  end
end
