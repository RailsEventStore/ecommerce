module Admin
  class NameStore
    def call(event)
      Store.find(event.data.fetch(:store_id)).update!(name: event.data.fetch(:name))
    end
  end
end
