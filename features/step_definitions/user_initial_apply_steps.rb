Given /^以下の利用開始前のユーザを登録する:$/ do |table|
  @new_users ||= []
  table.hashes.each do |hash|
    login_id = UserUid.find_by_uid(hash[:login_id])
    login_id.destroy if login_id
    u = User.new(:name => hash[:name], :email => hash[:email])
    u.user_uids.build(:uid => hash[:login_id], :uid_type => UserUid::UID_TYPE[:master])
    u.save!
    @new_users << u
  end
end

When /^登録した"([^\"]*)"人目のユーザの新規登録URLにアクセスする$/ do |id|
  target_user = @new_users[id.to_i-1]
  target_user.issue_activation_code
  target_user.save!
  visit signup_url(:code => target_user.activation_token)
end

Given /^プロフィール項目が登録されていない$/ do
  UserProfileMaster.destroy_all
end
