require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Page do
  fixtures :pages
  fixtures :contents
  fixtures :chapters

  before(:each) do
    # TODO ymlか読み込むと0がはいるため
    Page.all.each {|p| p.update_attributes(:parent_id=>nil) if p.parent_id==0 }
    @valid_attributes = {
      :last_modified_user_id => "1",
      :title => "value for display_name",
      :format_type => "hiki",
      :deleted_at => Time.now,
      :lock_version => "1"
    }
  end

  describe "ページの初期設定時" do
    it "新規ページ生成時はformat_typeがhtmlであること" do
      Page.new.format_type.should == 'html'
    end
  end

  # 常に最上位のページは1つ
  describe "#roots" do
    subject { Page.roots }
    its(:size) { should == 1 }
  end

  describe "#root" do
    subject { Page.root }
    its(:parent_id) { should be_nil }
  end

  describe "#edit(content, user)" do
    before do
      @page = Page.new(@valid_attributes)
      @page.edit(contents(:two), mock_model(User))
    end

    it "Historyが作成されること" do
      lambda{@page.save!}.should change(History,:count).by(1)
    end

    it "保存後のrevisionは1であること" do
      @page.save!; @page.reload
      @page.revision.should == 1
    end

    it "最新のコンテンツは'hogehogehoge'であること" do
      @page.save!
      @page.content.should == "hogehogehoge"
    end

    it "未保存でも最新のコンテンツは'hogehogehoge'であること" do
      @page.content.should == "hogehogehoge"
    end

    describe "同じ内容で保存した場合" do
      before do
        @page.save!
      end

      it "Historyを追加しないこと" do
        lambda{
          @page.edit(contents(:four), mock_model(User))
          @page.save!
        }.should_not change(History,:count)
      end
    end

    describe "再編集した場合" do
      before do
        @page.save!
        @page.reload
        @page.edit(contents(:three), mock_model(User))
        @page.save!
      end

      it "contentは新しいものであること" do
        @page.reload.content.should == "edit to revision 2"
      end
      it "contentの引数でrevisionを指定できること" do
        @page.reload.content(1).should == "hogehogehoge"
      end
    end

    describe "入力されたnew_historyがvalidでない場合" do
      before do
        @page.new_history.stub!(:valid?).and_return(false)
      end

      it "Pageもvalidでないこと" do
        @page.should_not be_valid
      end

      it "new_historyにエラーがあること" do
        @page.valid?
        @page.should have(1).errors_on(:new_history)
      end
    end
  end


  describe "has_history?" do
    before do
      @initial_page = Page.new(@valid_attributes.merge({:last_modified_user_id=>0}))
      @page = Page.new(@valid_attributes)
    end

    it "最終更新者がいないページはfalseがかえること" do
      @initial_page.has_history?.should be_false
    end

    it "それ以外はtrueがかえること" do
      @page.has_history?.should be_true
    end
  end

end
