class ChangePicturesColumnLimitOfData < ActiveRecord::Migration
  def self.up
    change_column :pictures, :data, :binary, :limit => 200.kilobyte
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
