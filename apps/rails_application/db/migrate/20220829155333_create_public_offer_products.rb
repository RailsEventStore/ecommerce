class CreatePublicOfferProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :public_offer_products, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name
      t.decimal :price
      t.timestamps
    end
  end
end
