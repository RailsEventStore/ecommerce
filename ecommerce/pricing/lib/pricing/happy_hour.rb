module Pricing
  class HappyHour
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def create(**kwargs)
      raise AlreadyCreated if @created

      apply HappyHourCreated.new(
        data: kwargs.merge(happy_hour_id: @id)
      )
    end

    private

    on HappyHourCreated do |_|
      @created = true
    end
  end
end
