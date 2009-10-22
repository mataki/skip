class CreateEntryHideOperations < ActiveRecord::Migration
  def self.up
    create_table :entry_hide_operations do |t|
      t.references :board_entry
      t.references :user
      t.text :comment
      t.string :operation_type

      t.timestamps
    end
  end

  def self.down
    drop_table :entry_hide_operations
  end
end
