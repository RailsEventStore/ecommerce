class DisablePgCrypto < ActiveRecord::Migration[6.1]
  def up
    disable_extension "pg_crypto"
  end

  def down
    enable_extension "pg_crypto"
  end
end
