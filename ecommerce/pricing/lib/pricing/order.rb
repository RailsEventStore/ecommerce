module Pricing
  class Order
    include AggregateRoot

    def initialize(id)
      @id = id
      @product_ids = []
    end

    def add_item(product_id)
      apply PriceItemAdded.new(
        data: {
          order_id: @id,
          product_id: product_id
        }
      )
    end

    def remove_item(product_id)
      apply PriceItemRemoved.new(
        data: {
          order_id: @id,
          product_id: product_id
        }
      )
    end

    def calculate_total_value(pricing_catalog, percentage_discount, happy_hours)
      total_value = @product_ids.sum { |product_id| pricing_catalog.price_for(product_id) }
      happy_hour_value = @product_ids.sum do |product_id|
        calculate_value_with_happy_hours(product_id, pricing_catalog, happy_hours)
      end

      discounted_value = percentage_discount.apply(happy_hour_value)
      apply(
        OrderTotalValueCalculated.new(
          data: {
            order_id: @id,
            total_amount: total_value,
            happy_hour_amount: happy_hour_value,
            discounted_amount: discounted_value
          }
        )
      )
    end

    def calculate_sub_amounts(pricing_catalog, percentage_discount, happy_hours)
      return if @product_ids.empty?

      sub_amounts_total = product_quantity_hash.map do |product_id, quantity|
        quantity * pricing_catalog.price_for(product_id)
      end
      sub_discounts = calculate_total_sub_discounts(pricing_catalog, percentage_discount, happy_hours)

      product_ids = product_quantity_hash.keys
      quantities = product_quantity_hash.values
      product_ids.zip(quantities, sub_amounts_total, sub_discounts) do |product_id, quantity, sub_amount, sub_discount|
        apply(
          PriceItemValueCalculated.new(
            data: {
              order_id: @id,
              product_id: product_id,
              quantity: quantity,
              amount: sub_amount,
              discounted_amount: sub_amount - sub_discount
            }
          )
        )
      end
    end

    private

    on PriceItemAdded do |event|
      @product_ids << event.data.fetch(:product_id)
    end

    on PriceItemRemoved do |event|
      @product_ids.delete(event.data.fetch(:product_id))
    end

    on PriceItemValueCalculated do |event|
    end

    on OrderTotalValueCalculated do |event|
    end

    def product_quantity_hash
      @product_quantity_hash ||= @product_ids.tally
    end

    def calculate_total_sub_discounts(pricing_catalog, percentage_discount, happy_hours)
      product_quantity_hash.map do |product_id, quantity|
        catalog_price_for_single = pricing_catalog.price_for(product_id)
        happy_hours_single = calculate_value_with_happy_hours(product_id, pricing_catalog, happy_hours)
        with_total_discount_single = percentage_discount.apply(happy_hours_single)

        quantity * (catalog_price_for_single - with_total_discount_single)
      end
    end

    def calculate_value_with_happy_hours(product_id, pricing_catalog, happy_hours)
      catalog_price = pricing_catalog.price_for(product_id)
      happy_hour_discount = happy_hours.discount_for(product_id, Time.now.utc.hour).to_i
      discount_object =
        if happy_hour_discount.positive?
          Discounts::PercentageDiscount.new(happy_hour_discount)
        else
          Discounts::NoPercentageDiscount.new
        end

      discount_object.apply(catalog_price)
    end
  end
end
