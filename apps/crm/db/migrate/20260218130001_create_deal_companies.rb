class CreateDealCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :deal_companies do |t|
      t.uuid :deal_uid, null: false
      t.uuid :company_uid, null: false
    end
    add_index :deal_companies, [:deal_uid, :company_uid], unique: true
  end
end
