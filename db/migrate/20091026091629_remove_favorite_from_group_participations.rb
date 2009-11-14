class RemoveFavoriteFromGroupParticipations < ActiveRecord::Migration
  def self.up
    remove_column :group_participations, :favorite
  end

  def self.down
    raise IrreversibleMigration
  end
end
