module Admin
  class RegisterStore
    def call(event)
      Store.create!(id: event.data.fetch(:store_id))
    end
  end
end
