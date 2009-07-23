require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BookmarkController do
  describe "route generation" do
    it "should map #list" do
      route_for(:controller => "bookmark", :action => "list", :uid => "mat.aki").should == {:path => "/user/mat.aki/bookmark", :method => "GET" }
    end
  end
  describe "route recognition" do
    it "should generate params for #list" do
      params_from(:get, "/user/mat.aki/bookmark").should == {:controller => "bookmark", :action => "list", :uid => "mat.aki"}
    end
  end
end
