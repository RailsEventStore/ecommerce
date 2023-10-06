module Infra
  class Transaction
    def initialize(container:)
      @container = container
    end
    
    def call
      @container.gateways[:default].transaction do
        yield
      end
    end
  end
end
