module Admin
  class StoresController < ApplicationController
    layout "application"

    def index
      render html: Admin::Rendering::StoresIndex.build(view_context), layout: true
    end

    def new
      store_id = SecureRandom.uuid
      render html: Admin::Rendering::StoresNew.build(view_context, store_id, nil), layout: true
    end

    def create
      store_id = params[:store_id]
      name = params[:name]

      ActiveRecord::Base.transaction do
        register_store(store_id)
        name_store(store_id, name)
      end

      redirect_to admin_stores_path, notice: "Store was successfully created"
    rescue Stores::AlreadyRegistered
      render html: Admin::Rendering::StoresNew.build(view_context, store_id, "Store was already registered"), layout: true
    rescue ArgumentError
      render html: Admin::Rendering::StoresNew.build(view_context, store_id, "Store name cannot be empty"), layout: true
    end

    def edit
      store = Store.find(params[:id])
      render html: Admin::Rendering::StoresEdit.build(view_context, store, nil), layout: true
    end

    def update
      store_id = params[:id]
      name = params[:name]

      name_store(store_id, name)

      redirect_to admin_stores_path, notice: "Store was successfully updated"
    rescue ArgumentError
      store = Store.find(store_id)
      render html: Admin::Rendering::StoresEdit.build(view_context, store, "Store name cannot be empty"), layout: true
    end

    private

    def register_store(store_id)
      command_bus.(::Stores::RegisterStore.new(store_id: store_id))
    end

    def name_store(store_id, name)
      command_bus.(::Stores::NameStore.new(store_id: store_id, name: ::Stores::StoreName.new(value: name)))
    end
  end
end
