class AddOpUrlToTenant < ActiveRecord::Migration
  def self.up
    add_column :tenants, :op_url, :string
  end

  def self.down
    remove_column :tenants, :op_url
  end
end
