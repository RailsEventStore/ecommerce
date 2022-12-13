event_store = Rails.configuration.event_store
broken_time_promotion_id = "2d790b70-63ea-4be8-9b32-69e396c93b07"
event = event_store.read.event("5c0d092a-0ceb-41ab-b92d-105b5d7ea8c2")

event.data[:label] = event_store
                       .read
                       .of_type("Pricing::TimePromotionLabeled")
                       .each
                       .select { |e| e.data[:time_promotion_id] == broken_time_promotion_id }.first.data[:label]

event.data[:discount] = event_store
                          .read
                          .of_type("Pricing::TimePromotionDiscountSet")
                          .each
                          .select { |e| e.data[:time_promotion_id] == broken_time_promotion_id }.first.data[:discount]

time_promotion_range_set = event_store
                             .read
                             .of_type("Pricing::TimePromotionRangeSet")
                             .each
                             .select { |e| e.data[:time_promotion_id] == broken_time_promotion_id }.first

event.data[:start_time] = time_promotion_range_set.data[:start_time]
event.data[:end_time] = time_promotion_range_set.data[:end_time]

event_store.overwrite([event])

