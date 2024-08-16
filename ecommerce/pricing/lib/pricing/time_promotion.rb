module Pricing
  class TimePromotion
    include AggregateRoot
    AlreadyCreated = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def create(discount, start_time, end_time, label)
      raise AlreadyCreated if @created
      apply TimePromotionCreated.new(
        data: {
          time_promotion_id: @id,
          discount: discount,
          start_time: start_time,
          end_time: end_time,
          label: label
        }
      )
    end

    private

    on TimePromotionCreated do |_|
      @created = true
    end

  end
end
