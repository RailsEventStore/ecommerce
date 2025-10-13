module Admin
  class Store < ApplicationRecord
    self.table_name = "admin_stores"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterStore.new, to: [::Stores::StoreRegistered])
      event_store.subscribe(NameStore.new, to: [::Stores::StoreNamed])
    end
  end
end
