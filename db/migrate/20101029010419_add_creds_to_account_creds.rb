class AddCredsToAccountCreds < ActiveRecord::Migration
  def self.up
    add_column :account_creds, :creds,   :text, :null => false
    add_column :account_creds, :cookies, :text, :null => false

    remove_column :account_creds, :cred_key
    remove_column :account_creds, :cred_guid
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
