# frozen_string_literal: true

ROM::SQL.migration do
  change do
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'

    create_table(:orders) do
      primary_key :id, :uuid, default: Sequel.function(:uuid_generate_v4)

      column :number, String
      column :customer, String
      column :state, String

      column :percentage_discount, BigDecimal, size: [8, 2]
      column :total_value, BigDecimal, size: [8, 2]
      column :discounted_value, BigDecimal, size: [8, 2]
      column :happy_hour_value, BigDecimal, size: [8, 2]

      column :total_value_updated_at, DateTime
      column :discount_updated_at, DateTime
    end
  end
end
