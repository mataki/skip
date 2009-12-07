class AddActiveToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :active, :boolean, :default => true

    add_index :pictures, :active

    change_column_default :pictures, :active, false
  end

  def self.down
    remove_column :pictures, :active
  end
end
