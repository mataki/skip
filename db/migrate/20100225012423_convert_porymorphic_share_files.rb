class ConvertPorymorphicShareFiles < ActiveRecord::Migration
  def self.up
    add_column :share_files, :owner_id, :integer, :null => false
    add_column :share_files, :owner_type, :string, :null => false
    remove_column :share_files, :owner_symbol
  end

  def self.down
    raise IrreversibleMigration
  end
end
