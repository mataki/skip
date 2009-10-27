class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents do |t|
      t.binary :data, :limit=>20.megabytes
      t.timestamps
    end
  end

  def self.down
    drop_table :contents
  end
end
