module Returns
  class CreateDraftReturn
    def call(event)
      Return.create!(
        uid: event.data[:return_id],
        order_uid: event.data[:order_id],
        status: "Draft",
        total_value: 0
      )
    end
  end

  # Backward compatibility alias
  CreateDraftRefund = CreateDraftReturn
end
