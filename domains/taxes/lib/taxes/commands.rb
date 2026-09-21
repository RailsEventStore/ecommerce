module Taxes
  class SetVatRate
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :vat_rate_code

    def initialize(product_id, vat_rate_code)
      @product_id = product_id
      @vat_rate_code = vat_rate_code
      valid = UUID.match?(@product_id) && @vat_rate_code.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class AddAvailableVatRate
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :available_vat_rate_id, :vat_rate

    def initialize(available_vat_rate_id, vat_rate)
      @available_vat_rate_id = available_vat_rate_id
      @vat_rate = Infra::Types::VatRate.new(vat_rate)
      valid = UUID.match?(@available_vat_rate_id)
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RemoveAvailableVatRate
    attr_reader :vat_rate_code

    def initialize(vat_rate_code)
      @vat_rate_code = vat_rate_code
      raise Infra::Command::Invalid unless @vat_rate_code.is_a?(String)
    end
  end
end
