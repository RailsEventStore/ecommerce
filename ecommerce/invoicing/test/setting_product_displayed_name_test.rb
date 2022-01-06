require_relative "test_helper"

module Invoicing
  class SettingProductDisplayedNameTest < Test
    cover "Invoicing::SetProductNameDisplayedOnInvoiceHandler"

    def test_adding_to_invoice
      product_id = SecureRandom.uuid
      name_displayed = 'test'
      stream = "Invoicing::Product$#{product_id}"

      assert_events(
        stream,
        ProductNameDisplayedSet.new(
          data: {
            product_id: product_id,
            name_displayed: name_displayed,
          }
        )
      ) { set_product_name_displayed(product_id, name_displayed) }
    end
  end
end