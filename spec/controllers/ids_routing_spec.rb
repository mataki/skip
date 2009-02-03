require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do
  describe "route generation" do
    it "should map #show" do
      route_for(:controller => "ids", :action => "show", :user => 1).should == "/id/1"
    end
    it "should map #show" do
      route_for(:controller => "ids", :action => "show", :user => "").should == "/id/"
    end
  end

  describe "route recognition" do
    it "should generate params for #show" do
      params_from(:get, "/id/1").should == {:controller => "ids", :action => "show", :user => "1"}
    end
  end
end
