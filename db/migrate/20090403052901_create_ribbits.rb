class CreateRibbits < ActiveRecord::Migration
  def self.up
    create_table :ribbits do |t|
      t.string :purpose_number
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :ribbits
  end
end
