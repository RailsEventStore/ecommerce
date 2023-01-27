module ClientAuthentication
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end

  class Configuration
    def initialize(event_store)
      @event_store = event_store
    end

    def call
    end
  end
end
