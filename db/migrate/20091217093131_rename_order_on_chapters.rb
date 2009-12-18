class RenameOrderOnChapters < ActiveRecord::Migration
  def self.up
    rename_column :chapters, :order, :position
  end

  def self.down
    rename_column :chapters, :position, :order
  end
end
