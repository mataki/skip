class DropUserUids < ActiveRecord::Migration
  def self.up
    drop_table :user_uids
  end

  def self.down
    raise IrreversibleMigration
  end
end
