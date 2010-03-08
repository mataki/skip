class AddTenantToUserProfileMasters < ActiveRecord::Migration
  def self.up
    change_table :user_profile_masters do |t|
      t.references :tenant, :null => false
      t.index :tenant_id
    end
  end

  def self.down
    change_table :user_profile_masters do |t|
      t.remove_references :tenant
    end
  end
end
