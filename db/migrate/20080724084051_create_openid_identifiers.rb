class CreateOpenidIdentifiers < ActiveRecord::Migration
  def self.up
    create_table :openid_identifiers do |t|
      t.string :url
      t.integer :account_id

      t.timestamps
    end
    Account.all.each do |account|
      if account.ident_url
        OpenidIdentifier.create!(:url => account.ident_url, :account_id => account.id)
      end
    end
    remove_column :accounts, :ident_url
    add_index :openid_identifiers, :url, :unique => true
  end

  def self.down
    add_column :accounts, :ident_url, :string
    OpenidIdentifier.all.each do |openid_identifier|
      account = Account.find(openid_identifier.account_id)
      account.ident_url = openid_identifier.url
      account.save!
    end

    drop_table :openid_identifiers
  end
end
