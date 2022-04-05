# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :crm_customers do
      column :name, String, null: false
      column :id, :uuid, primary_key: true
    end
  end
end
