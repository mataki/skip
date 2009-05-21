class CreateOauthProviders < ActiveRecord::Migration
  def self.up
    create_table :oauth_providers do |t|
      t.string :app_name
      t.string :token
      t.string :secret
      t.timestamps
    end
    add_index :oauth_providers, :app_name, :unique => true
  end

  def self.down
    drop_table :oauth_providers
  end
end
