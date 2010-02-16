class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.references :user
      t.string :email, :null => false , :default => ''
      t.string :subject
      t.text :body
      t.timestamps

      t.index :user
    end
  end

  def self.down
    drop_table :invitations
  end
end
