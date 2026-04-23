module TimePromotions
  class CreateTimePromotion
    def call(event)
      broadcast_new_row(create_record(event))
    end

    private

    def create_record(event)
      TimePromotion.create!(record_attributes(event))
    end

    def record_attributes(event)
      event.data.slice(:discount, :start_time, :end_time, :label).merge(id: event.data.fetch(:time_promotion_id))
    end

    def broadcast_new_row(time_promotion)
      Broadcaster.new.call(row_html(time_promotion))
    end

    def row_html(time_promotion)
      <<~HTML
        <tr class="border-t">
          <td class="py-2">#{time_promotion.label}</td>
          <td class="py-2">#{time_promotion.discount}</td>
          <td class="py-2">#{time_promotion.start_time.strftime("%Y-%m-%d %H:%M")}</td>
          <td class="py-2">#{time_promotion.end_time.strftime(("%Y-%m-%d %H:%M"))}</td>
        </tr>
      HTML
    end
  end
end
