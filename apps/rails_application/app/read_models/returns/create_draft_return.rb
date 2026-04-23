module Returns
  class CreateDraftReturn
    def call(event)
      Return.create!(
        uid: event.data.fetch(:return_id),
        order_uid: event.data.fetch(:order_id),
        status: "Draft",
        total_value: 0
      )
    end
  end

  # Backward compatibility alias
  CreateDraftRefund = CreateDraftReturn
end
