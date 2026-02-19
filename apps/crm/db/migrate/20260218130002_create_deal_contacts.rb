class CreateDealContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :deal_contacts do |t|
      t.uuid :deal_uid, null: false
      t.uuid :contact_uid, null: false
    end
    add_index :deal_contacts, [:deal_uid, :contact_uid], unique: true
  end
end
