# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = 'test'
require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
require 'spec/autorun'
require 'spec/rails'

# Uncomment the next line to use webrat's matchers
#require 'webrat/integrations/rspec-rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = true
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses its own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end

def admin_login
  session[:user_code] = '111111'
  session[:prepared] = true
  u = stub_model(User, :symbol => 'uid:admin', :admin => true, :name => '管理者', :crypted_password => '123456789')
  u.stub!(:active?).and_return(true)
  if defined? controller
    controller.stub!(:current_user).and_return(u)
  else
    # helperでも使えるように
    stub!(:current_user).and_return(u)
  end
  u
end

def user_login
  session[:user_code] = '111111'
  session[:prepared] = true
  u = stub_model(User, :symbol => 'uid:user', :admin => false, :name => '一般ユーザ', :crypted_password => '123456789', :code => "111111", :status => "ACTIVE", :created_on => 10.day.ago)
  u.stub!(:active?).and_return(true)
  u.stub!(:user_access).and_return(stub_model(UserAccess, :access_count => 4, :last_access => 1.day.ago))
  if defined? controller
    controller.stub!(:current_user).and_return(u)
  else
    # helperでも使えるように
    stub!(:current_user).and_return(u)
  end
  u
end

def mock_record_invalid
  fa = mock_model(ActiveRecord::Base)
  fa.errors.stub!(:full_messages).and_return([])
  ActiveRecord::RecordInvalid.new(fa)
end

def create_user options = {}
  options[:user_options] ||= {}
  user = User.new({ :name => 'ほげ ほげ', :password => 'Password1', :password_confirmation => 'Password1', :reset_auth_token => nil, :email => SkipFaker.email, :section => 'Programmer'}.merge(options[:user_options]))
  user.status = options[:status] || 'ACTIVE'
  user.admin = options[:user_options][:admin] || false
  if options[:user_uid_options]
    user_uid = UserUid.new({ :uid => '123456', :uid_type => 'MASTER' }.merge(options[:user_uid_options]))
    user.user_uids << user_uid
  end
  user.save!
  yield user if block_given?
  user
end

def unused_user_login
  session[:user_code] = '111111'
  session[:prepared] = true
  u = stub_model(User)
  u.stub!(:admin).and_return(false)
  u.stub!(:active?).and_return(false)
  u.stub!(:unused?).and_return(true)
  u.stub!(:name).and_return('未登録ユーザ')
  u.stub!(:crypted_password).and_return('123456789')
  if defined? controller
    controller.stub!(:current_user).and_return(u)
  else
    # helperでも使えるように
    stub!(:current_user).and_return(u)
  end
  u
end

def valid_group_category
  group_category = GroupCategory.new({
    :code => 'DEPT',
    :name => '部署',
    :icon => 'group_gear',
    :description => '部署用のグループカテゴリ',
    :initial_selected => false
  })
  group_category
end

def create_group_category(options = {})
  group_category = valid_group_category
  group_category.attributes = options
  group_category.save!
  group_category
end

def create_group(options = {})
  group = Group.new({:name => 'SKIP開発', :description => 'SKIP開発中', :protected => false, :gid => 'skip_dev', :deleted_at => nil}.merge(options))
  group.deleted_at = options[:deleted_at]
  group.group_category_id = create_group_category(:initial_selected => true).id if group.group_category_id == 0
  yield group if block_given?
  group.save!
  group
end

def create_group_participation(options = {})
  group_participation = GroupParticipation.new({:user_id => 1, :group_id => 1, :waiting => 0, :owned => 0}.merge(options))
  group_participation.save!
  group_participation
end

def create_board_entry options = {}
  board_entry = BoardEntry.new({:title => 'とある記事',
                               :contents => 'とある記事の内容',
                               :date => Date.today,
                               :user_id => 1,
                               :last_updated => Date.today,
                               :category => '',
                               :publication_type => 'public'}.merge(options))
  yield board_entry if block_given?
  board_entry.save!
  create_entry_publications(:board_entry_id => board_entry.id, :symbol => Symbol::SYSTEM_ALL_USER) if board_entry.public?
  board_entry
end

def create_entry_publications options = {}
  entry_publication = EntryPublication.new({:board_entry_id => 1, :symbol => ''}.merge(options))
  entry_publication.save!
  entry_publication
end

def create_board_entry_comment options = {}
  board_entry_comment = BoardEntryComment.new({:board_entry_id => 1,
                                               :contents => 'とあるコメント',
                                               :user_id => 1}.merge(options))
  board_entry_comment.save!
  board_entry_comment
end

# ActionController::TestProcess#fixture_file_uploadを利用した方がよいかも
def mock_uploaed_file options = {}
  file = mock('file', { :original_filename => "file1.png", :content_type => "image/png", :size => 1000, :read => "" }.merge(options))
  file.stub!(:is_a?).with(ActionController::UploadedFile).and_return(true)
  # 以下をやらないとパラメータの中身がHashかどうかのチェックがらしく、リクエストが飛ばなくなるので
  file.stub!(:is_a?).with(Hash).and_return(false)
  file.stub!(:is_a?).with(Array).and_return(false)
  file
end

def create_user_profile_master_category(options = {})
  profile_master_category = UserProfileMasterCategory.new({
    :name => '基本情報',
    :description => '基本情報のカテゴリです'
  }.merge(options))
  profile_master_category.save!
  profile_master_category
end

def create_user_profile_master(options = {})
  profile_master = UserProfileMaster.new({
    :user_profile_master_category_id => 1,
    :name => '自己紹介',
    :input_type => 'richtext'
  }.merge(options))
  profile_master.save_without_validation!
  profile_master
end

# --- OpenID Provider関連テスト用
def checkid_request_params
  { 'openid.ns' => OpenID::OPENID2_NS,
    'openid.mode' => 'checkid_setup',
    'openid.realm' => 'http://test.com/',
    'openid.trust_root' => 'http://test.com/',
    'openid.return_to' => 'http://test.com/return',
    'openid.claimed_id' => 'http://dennisbloete.de/',
    'openid.identity' => 'http://openid.innovated.de/dbloete' }
end
def identifier(user)
  "http://test.host/id/#{user.code}"
end

# --- flash.nowがRails 2.3 + RSpec 1.2.7でテストをパスしない問題に対する対応
# https://rspec.lighthouseapp.com/projects/5645/tickets/98-11834-fake-controller-flash-object
def stub_flash_now
  controller.instance_eval{flash.stub!(:sweep)}
end

module SkipEmbedded
  class InitialSettings
    # テストの時のみ値の入れ替えを可能にしたいので。
    def self.[]=(key, val)
      instance.instance_variable_set(:@config, instance.instance_variable_get(:@config).dup)
      instance.instance_variable_get(:@config)[key] = val
    end
  end
end

######skip関連のテストで必要
class ApplicationController;skip_before_filter :sso; end
