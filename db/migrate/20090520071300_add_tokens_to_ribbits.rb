class AddTokensToRibbits < ActiveRecord::Migration
  def self.up
    change_table(:ribbits) do |t|
      t.string :access_token
      t.string :access_secret
      t.string :guid
    end
  end

  def self.down
    change_table(:ribbits) do |t|
      t.remove :access_token
      t.remove :access_secret
      t.remove :guid
    end
  end
end
