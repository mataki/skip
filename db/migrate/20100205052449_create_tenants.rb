class CreateTenants < ActiveRecord::Migration
  def self.up
    create_table :tenants do |t|
      t.string :name, :null => false
      t.status :string
      t.timestamps
    end
  end

  def self.down
    drop_table :tenants
  end
end
