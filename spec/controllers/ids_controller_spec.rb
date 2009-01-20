require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe IdsController, "#show" do
  describe "登録済みのユーザのURLの場合" do
    before do
      User.should_receive(:find_by_code).with("111111").and_return(@user = mock_model(User, :code => "111111"))
    end
    it "ページが表示される" do
      get :show, :user => "111111"
      response.should be_success
    end
    it "ヘッダーに'X-XRDS-Location'が含まれること" do
      get :show, :user => "111111"
      response.headers["X-XRDS-Location"].should == identifier(@user) + ".xrds"
    end
    describe "xrdsフォーマットの場合" do
      it "xrdsを返すこと" do
        get :show, :user => "111111", :format => "xrds"
        response.headers["type"].should == "application/xrds+xml; charset=utf-8"
      end
    end
  end
  describe "存在しないユーザのURLの場合" do
    it "ActiveRecord::RecordNotFoundになること" do
      User.should_receive(:find_by_code).and_return(nil)
      lambda do
        get :show, :user => "111111"
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
