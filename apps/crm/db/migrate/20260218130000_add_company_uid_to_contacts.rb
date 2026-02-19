class AddCompanyUidToContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :contacts, :company_uid, :uuid
  end
end
