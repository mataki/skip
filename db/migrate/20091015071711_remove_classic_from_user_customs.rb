class RemoveClassicFromUserCustoms < ActiveRecord::Migration
  def self.up
    remove_column :user_customs, :classic
  end

  def self.down
    raise IrreversibleMigration
  end
end
