module Returns
  class RemoveItemFromReturn
    def call(event)
      ActiveRecord::Base.transaction { apply(event) }
    end

    private

    def apply(event)
      return_record = Return.find_by!(uid: event.data.fetch(:return_id))
      item = return_record.return_items.find_by!(product_uid: event.data.fetch(:product_id))

      return_record.total_value -= item.price
      item.quantity -= 1

      return_record.save!
      item.quantity > 0 ? item.save! : item.destroy!
    end
  end

  # Backward compatibility alias
  RemoveItemFromRefund = RemoveItemFromReturn
end
