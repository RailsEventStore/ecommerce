class ContactsController < ApplicationController
  def index
    @contacts = Contacts.all
  end

  def show
    @contact = Contacts.find_by_uid(params[:id])
    @company = Companies.find_by_uid(@contact.company_uid) if @contact.company_uid.present?
  end

  def new
  end

  def create
    contact_id = SecureRandom.uuid
    contact_params = params.require(:contact).permit(:name, :email, :phone, :linkedin_url)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::RegisterContact.new(contact_id, contact_params[:name]))
      command_bus.call(Crm::SetContactEmail.new(contact_id, contact_params[:email])) if contact_params[:email].present?
      command_bus.call(Crm::SetContactPhone.new(contact_id, contact_params[:phone])) if contact_params[:phone].present?
      command_bus.call(Crm::SetContactLinkedinUrl.new(contact_id, contact_params[:linkedin_url])) if contact_params[:linkedin_url].present?
    end
    redirect_to contacts_path
  end

  def edit
    @contact = Contacts.find_by_uid(params[:id])
    @companies = Companies.all
  end

  def update
    contact_params = params.require(:contact).permit(:email, :phone, :linkedin_url, :company_id)

    ActiveRecord::Base.transaction do
      command_bus.call(Crm::SetContactEmail.new(params[:id], contact_params[:email])) if contact_params[:email].present?
      command_bus.call(Crm::SetContactPhone.new(params[:id], contact_params[:phone])) if contact_params[:phone].present?
      command_bus.call(Crm::SetContactLinkedinUrl.new(params[:id], contact_params[:linkedin_url])) if contact_params[:linkedin_url].present?
      command_bus.call(Crm::AssignContactToCompany.new(SecureRandom.uuid, params[:id], contact_params[:company_id])) if contact_params[:company_id].present?
    end
    redirect_to contact_path(params[:id])
  end
end
