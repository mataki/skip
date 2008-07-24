require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenidIdentifier do
  before(:each) do
    @openid_identifier = OpenidIdentifier.new({ :url => "http://hoge.example.com", :account_id => 1})
  end

  it "should be valid" do
    @openid_identifier.should be_valid
  end
end


describe OpenidIdentifier, '#url' do
  before do
    @openid_identifier = OpenidIdentifier.new({ :url => "http://hoge.example.com/", :account_id => 1})
  end

  describe '不正な URL を指定した場合' do
    before do
      @openid_identifier.url = '::::::'
    end

    it { @openid_identifier.should_not be_valid }
    it { @openid_identifier.should have(1).errors_on(:url) }
  end

  describe '正規化されていない URL を指定した場合' do
    before do
      @openid_identifier.url = 'example.com'
    end

    it '保存時に正規化されること' do
      proc {
        @openid_identifier.save
      }.should change(@openid_identifier, :url).from('example.com').to('http://example.com/')
    end
  end

  describe 'update_attribute でも' do
    it '正規化されること' do
      proc {
        @openid_identifier.update_attribute(:url, 'example.com')
      }.should change(@openid_identifier, :url).from(nil).to('http://example.com/')
    end
  end
end

