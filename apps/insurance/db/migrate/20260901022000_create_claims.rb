class CreateClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :claims do |t|
      t.uuid :claim_id
      t.uuid :policy_id
      t.string :description
      t.decimal :amount
      t.string :state

      t.timestamps
    end
  end
end
