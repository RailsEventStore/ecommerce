require_relative 'test_helper'
module Stores
  class InvoiceRegistrationTest < Test
    cover "Stores*"

    def test_invoice_should_get_registered
      store_id = SecureRandom.uuid
      invoice_id = SecureRandom.uuid
      assert register_invoice(store_id, invoice_id)
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      invoice_id = SecureRandom.uuid
      invoice_registered = Stores::InvoiceRegistered.new(data: { store_id: store_id, invoice_id: invoice_id })
      assert_events("Stores::Store$#{store_id}", invoice_registered) do
        register_invoice(store_id, invoice_id)
      end
    end

    private

    def register_invoice(store_id, invoice_id)
      run_command(RegisterInvoice.new(store_id: store_id, invoice_id: invoice_id))
    end
  end
end
