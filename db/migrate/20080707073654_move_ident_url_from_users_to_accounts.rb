class MoveIdentUrlFromUsersToAccounts < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.remove :ident_url
    end

    change_table :accounts do |t|
      t.string :ident_url
    end
  end

  def self.down
    change_table :users do |t|
      t.string :ident_url
    end

    change_table :accounts do |t|
      t.remove :ident_url
    end
  end
end
