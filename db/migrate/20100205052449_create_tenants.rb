class CreateTenants < ActiveRecord::Migration
  def self.up
    create_table :tenants do |t|
      t.string :name, :null => false
      t.status :string
      t.timestamps
    end

    change_table :users do |t|
      t.references :tenant, :null => false
      t.index :tenant_id
    end

    change_table :board_entries do |t|
      t.references :tenant, :null => false
      t.index :tenant_id
    end

    change_table :share_files do |t|
      t.references :tenant, :null => false
      t.index :tenant_id
    end

    change_table :groups do |t|
      t.references :tenant, :null => false
      t.index :tenant_id
    end

    change_table :group_categories do |t|
      t.references :tenant, :null => false
      t.index :tenant_id
    end
  end

  def self.down
    drop_table :tenants

    change_table :users do |t|
      t.remove_references :tenant
    end

    change_table :board_entries do |t|
      t.remove_references :tenant
    end

    change_table :share_files do |t|
      t.remove_references :tenant
    end

    change_table :groups do |t|
      t.remove_references :tenant
    end

    change_table :group_categories do |t|
      t.remove_references :tenant
    end
  end
end
