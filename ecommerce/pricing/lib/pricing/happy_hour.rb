module Pricing
  class HappyHour
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def create(**kwargs)
      # This is an implicit validation based on the @id only.
      # The id is internal and user does not specify it.
      # I'd rather validate it by code or another user input that we want to keep unique.
      raise AlreadyCreated if @created

      apply HappyHourCreated.new(
        data: kwargs.merge(id: @id)
      )
    end

    private

    on HappyHourCreated do |_|
      @created = true
    end
  end
end
