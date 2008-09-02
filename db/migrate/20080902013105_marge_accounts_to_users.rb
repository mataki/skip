class MargeAccountsToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string :crypted_password
      t.string :status
    end
    # データ移行
    User.transaction do
      Account.all.each do |account|
        user = User.find_by_uid(account.code)
        # 見つからない
        unless user
          #  新規つくってパスワード移行して未登録フラグ
          user = User.new({ :email => account.email, :name => account.name, :extension => '000000',
                            :section => account.section, :introduction => '00000',
                          })
          user.crypted_password = account.crypted_password
          user.status = 'UNUSED'
          user.user_uids << UserUid.new({ :uid => account.code, :uid_type => 'MASTER' })
          user.save!
          # 見つかった
        else
          #  退職じゃない
          #   見つかったのに対してパスワードを移行して、登録済みフラグ
          #  退職している
          #   見つかったのに対してパスワードを移行して、退職フラグ
          user.status = user.retired ? 'RETIRED' : 'ACTIVE'
          user.crypted_password = account.crypted_password
          user.save!
        end
        # openid_identifiersのaccount_idをuser_idへ移行
        openid_identifiers = account.openid_identifiers
        openid_identifiers.each do |oi|
          oi.account_id = user.id
          oi.save!
        end
      end
    end
    rename_column :openid_identifiers, :account_id, :user_id
    remove_column :users, :retired
    drop_table :accounts
  end

  def self.down
    create_table :accounts do |t|
      t.string   "code",             :default => "", :null => false
      t.string   "name",             :default => "", :null => false
      t.string   "email"
      t.string   "section",          :default => "", :null => false
      t.string   "crypted_password", :default => "", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    rename_column :openid_identifiers, :user_id, :account_id

    remove_column :users, :crypted_password
    remove_column :users, :status
    add_column :users, :retired, :boolean, :default => false, :nill => false
  end
end

class Account < ActiveRecord::Base
  has_many :openid_identifiers
end
