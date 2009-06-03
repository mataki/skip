class AddEnableToOauthProviders < ActiveRecord::Migration
  def self.up
    add_column :oauth_providers, :enable, :boolean, :default => false
  end

  def self.down
    remove_column :oauth_providers, :enable
  end
end
