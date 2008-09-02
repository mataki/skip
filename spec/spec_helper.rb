# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rubygems'
require 'test/unit'
require 'spec'
require 'spec/rails'

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
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

def admin_login
  session[:user_code] = '111111'
  session[:prepared] = true
  u = stub_model(User)
  u.stub!(:admin).and_return(true)
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
  u = stub_model(User)
  u.stub!(:admin).and_return(false)
  u.stub!(:active?).and_return(true)
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

def create_account(options = {})
  account = Account.new({
    :code => '111111',
    :name => '山田　太郎',
    :email => '111111@openskip.org',
    :section => 'プログラマ',
    :password => 'password',
    :password_confirmation => 'password'}.merge(options))
  account.save
  account
end

def create_ranking(options = {})
    ranking = Ranking.new({
      :url => 'http://user.openskip.org/',
      :title => 'SUG',
      :extracted_on => Date.today,
      :amount => 1,
      :contents_type => 'entry_access'}.merge(options))
    ranking.save
    ranking
end

def create_user options = {}
  user = User.new({ :name => 'ほげ ほげ', :email => 'hoge@hoge.com', :section => 'section',
                    :extension => '000000', :introduction => '自己紹介文',
                    :password => 'password', :password_confirmation => 'password'}.merge(options))
  user.save
  user
end

######skip関連のテストで必要
class ApplicationController;skip_before_filter :sso; end

