class ContactsController < ApplicationController
  def index
    @contacts = Contacts.all
  end

  def show
    @contact = Contacts.find_by_uid(params[:id])
  end

  def new
  end

  def create
    contact_id = SecureRandom.uuid
    contact_params = params.require(:contact).permit(:name, :email, :phone, :linkedin_url)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::RegisterContact.new(contact_id: contact_id, name: contact_params[:name]))
      command_bus.call(Crm::SetContactEmail.new(contact_id: contact_id, email: contact_params[:email])) if contact_params[:email].present?
      command_bus.call(Crm::SetContactPhone.new(contact_id: contact_id, phone: contact_params[:phone])) if contact_params[:phone].present?
      command_bus.call(Crm::SetContactLinkedinUrl.new(contact_id: contact_id, linkedin_url: contact_params[:linkedin_url])) if contact_params[:linkedin_url].present?
    end
    redirect_to contacts_path
  end

  def edit
    @contact = Contacts.find_by_uid(params[:id])
  end

  def update
    contact_params = params.require(:contact).permit(:email, :phone, :linkedin_url)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::SetContactEmail.new(contact_id: params[:id], email: contact_params[:email])) if contact_params[:email].present?
      command_bus.call(Crm::SetContactPhone.new(contact_id: params[:id], phone: contact_params[:phone])) if contact_params[:phone].present?
      command_bus.call(Crm::SetContactLinkedinUrl.new(contact_id: params[:id], linkedin_url: contact_params[:linkedin_url])) if contact_params[:linkedin_url].present?
    end
    redirect_to contact_path(params[:id])
  end
end
