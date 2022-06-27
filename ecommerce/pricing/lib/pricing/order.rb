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
      total_value = @product_ids.sum do |product_id|
        calculate_value_with_happy_hours(product_id, pricing_catalog, happy_hours)
      end

      discounted_value = percentage_discount.apply(total_value)
      apply(
        OrderTotalValueCalculated.new(
          data: {
            order_id: @id,
            total_amount: total_value,
            discounted_amount: discounted_value
          }
        )
      )
    end

    def calculate_sub_amounts(pricing_catalog, percentage_discount, happy_hours)
      return if @product_ids.empty?
      product_quantity_hash = @product_ids.tally
      product_ids = product_quantity_hash.keys
      quantities = product_quantity_hash.values
      sub_amounts = product_quantity_hash.map do |product_id, quantity|
        quantity * calculate_value_with_happy_hours(product_id, pricing_catalog, happy_hours)
      end
      total_value = sub_amounts.sum
      total_discount = percentage_discount.discount(total_value)
      sub_discounts = Math::MoneySplitter.new(total_discount, sub_amounts).call
      product_ids.zip(quantities, sub_amounts, sub_discounts) do |product_id, quantity, sub_amount, sub_discount|
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

    def calculate_value_with_happy_hours(product_id, pricing_catalog, happy_hours)
      catalog_price = pricing_catalog.price_for(product_id)
      happy_hour_discount = happy_hours.discount_for(product_id, Time.now.utc.hour).to_i
      discount_object = happy_hour_discount.positive? ?
        Discounts::PercentageDiscount.new(happy_hour_discount) :
        Discounts::NoPercentageDiscount.new

      discount_object.apply(catalog_price)
    end
  end
end
