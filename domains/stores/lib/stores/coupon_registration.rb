module Stores
  class CouponRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(coupon_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def coupon_registered_event(cmd)
      CouponRegistered.new(
        data: {
          store_id: cmd.store_id,
          coupon_id: cmd.coupon_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
