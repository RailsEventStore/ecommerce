module TimePromotions
  class CreateTimePromotion < Infra::EventHandler
    def call(event)
      time_promotion = TimePromotion.create!(event.data.slice(:code, :discount, :start_time, :end_time, :label).merge(id: event.data[:time_promotion_id]))
      Broadcaster.new.call(<<~HTML
        <tr class="border-t">
          <td class="py-2">#{time_promotion.label}</td>
          <td class="py-2">#{time_promotion.discount}</td>
          <td class="py-2">#{time_promotion.start_time}</td>
          <td class="py-2">#{time_promotion.end_time}</td>
        </tr>
      HTML
)
    end
  end
end
