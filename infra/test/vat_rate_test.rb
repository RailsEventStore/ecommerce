require_relative "test_helper"

module Infra
  class VatRateTest < Minitest::Test
    cover "Infra::Types::VatRate"

    def test_comparable
      assert_equal(0, vat.new(code: '10', rate: 10.to_d) <=> vat.new(code: 'ten', rate: 10.to_d))
      assert_equal(1, vat.new(code: '11', rate: 11.to_d) <=> vat.new(code: 'ten', rate: 10.to_d))
    end

    private

    def vat
      Infra::Types::VatRate
    end
  end
end