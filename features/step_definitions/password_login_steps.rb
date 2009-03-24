Given /ログインページを表示している/ do
  visit "/platform"
end

Given /^ログインIDが"(.*)"でパスワードが"(.*)"のユーザを作成する$/ do |id, password|
  u = User.new({ :name => 'ほげ ほげ', :password => password, :password_confirmation => password, :reset_auth_token => nil, :email => "a_user@example.com" })
  u.user_uids.build(:uid => id, :uid_type => 'MASTER')
  u.build_user_access(:last_access => Time.now, :access_count => 0)
  u.save!
  u.status = "ACTIVE"
  u.save!
end

