module TimePromotions
  class Broadcaster
    def call(content)
      Turbo::StreamsChannel.broadcast_append_to(
        "time_promotions",
        target: "time_promotions_table",
        html: content)
    end
  end
end