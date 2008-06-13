require File.dirname(__FILE__) + '/../spec_helper'

describe UserUid do
  before(:each) do
    @user_uid = UserUid.new
  end
end

describe User,"'s class methods" do
  fixtures :users
  before(:each) do
    @user = users(:a_user)
  end

  it "check_uid" do
    UserUid.check_uid("101010", "101010").should == "登録可能です"
    UserUid.check_uid("101010", "101011").should_not == "登録可能です"
    UserUid.check_uid(SkipFaker.rand_char(3), "101011").should_not == "登録可能です"
    UserUid.check_uid(SkipFaker.rand_char(32), "101011").should_not == "登録可能です"
    UserUid.check_uid("_abc", "101010").should == "登録可能です"
    UserUid.check_uid("+abc", "101010").should_not == "登録可能です"
    UserUid.check_uid(@user.uid,"101010").should_not == "登録可能です"
  end
end
