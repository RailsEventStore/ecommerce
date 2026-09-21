module Invoicing
  class AddInvoiceItem
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :invoice_id, :product_id, :quantity, :unit_price, :vat_rate

    def initialize(invoice_id, product_id, quantity, unit_price, vat_rate)
      @invoice_id = invoice_id
      @product_id = product_id
      @quantity = quantity
      @unit_price = BigDecimal(unit_price)
      @vat_rate = Infra::Types::VatRate.new(vat_rate)
      valid = UUID.match?(@invoice_id) && UUID.match?(@product_id) && @quantity.instance_of?(Integer) && @quantity > 0 && @unit_price >= 0
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class IssueInvoice
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :invoice_id, :issue_date

    def initialize(invoice_id, issue_date)
      @invoice_id = invoice_id
      @issue_date = issue_date
      valid = UUID.match?(@invoice_id) && @issue_date.is_a?(Date)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetPaymentDate
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :invoice_id, :payment_date

    def initialize(invoice_id, payment_date)
      @invoice_id = invoice_id
      @payment_date = payment_date
      valid = UUID.match?(@invoice_id) && @payment_date.is_a?(Date)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetBillingAddress
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :invoice_id, :tax_id_number, :postal_address

    def initialize(invoice_id, tax_id_number, postal_address)
      @invoice_id = invoice_id
      @tax_id_number = tax_id_number
      @postal_address = Infra::Types::PostalAddress.new(postal_address)
      valid = UUID.match?(@invoice_id) && (@tax_id_number.nil? || @tax_id_number.is_a?(String))
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetProductNameDisplayedOnInvoice
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :name_displayed

    def initialize(product_id, name_displayed)
      @product_id = product_id
      @name_displayed = name_displayed
      valid = UUID.match?(@product_id) && @name_displayed.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
