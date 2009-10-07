class AddDefaultSendMailToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :default_send_mail, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :groups, :default_send_mail
  end
end
