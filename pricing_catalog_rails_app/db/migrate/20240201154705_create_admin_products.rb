class CreateAdminProducts < ActiveRecord::Migration[7.1]
  def change
    AdminCatalog::Migration.new.change
  end
end
