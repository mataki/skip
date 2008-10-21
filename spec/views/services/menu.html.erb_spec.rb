require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/services/menu.html.erb" do
  include ServicesHelper
  include ActionController::UrlWriter

  it "ログアウトのURLがホストを含んでいること" do
    render "/services/menu.html.erb"

    response.should have_tag("div#services") do
      with_tag("a[href=#{url_for(:controller => '/platform', :action => :logout, :host => "test.host", :only_path => false, :protocol => "http://")}]")
    end
  end
end
