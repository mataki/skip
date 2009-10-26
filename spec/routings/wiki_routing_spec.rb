require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WikiController do
  describe 'route generation' do
    it 'should map #index' do
      route_for(:controller => 'wiki', :action => 'show', :id => 'トップページ').should == {:path => '/wiki/show/トップページ', :method=>'GET'}
    end
  end

  describe 'route recognization' do
    it 'should generate params for #index' do
      params_from(:get, '/wiki/show/トップページ').should == {:controller=>'wiki', :action=>'show', :id=>'トップページ'}
    end
  end
end
