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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserProfileMaster do
  describe UserProfileMaster, '.valid_presence_of_category' do
    describe 'user_profile_master_categoryに対象のカテゴリが存在する場合' do
      before do
        @user_profile_master = create_user_profile_master(:user_profile_master_category_id => create_user_profile_master_category.id)
      end
      it 'validationに成功すること' do
        @user_profile_master.send!(:valid_presence_of_category).should be_true
      end
    end
    describe 'user_profile_master_categoryに対象のカテゴリが存在しない場合' do
      before do
        @user_profile_master = create_user_profile_master
      end
      it 'validationに失敗すること' do
        @user_profile_master.send!(:valid_presence_of_category).should be_false
      end
      it 'エラーメッセージが設定されること' do
        lambda do
          @user_profile_master.send!(:valid_presence_of_category)
        end.should change(@user_profile_master.errors, :size).from(0).to(1)
      end
    end
  end
end

describe UserProfileMaster, "#input_type_processer" do
  before do
    @master = create_user_profile_master(:input_type => "text_field")
  end
  it "TextFieldのインスタンスが返ってくること" do
    @master.input_type_processer.should be_is_a(UserProfileMaster::TextFieldProcesser)
  end
end

describe UserProfileMaster, ".input_type_option" do
  it "セレクトボックス用の配列が返ってくること" do
    UserProfileMaster.input_type_option.size.should == 10
  end
end
describe UserProfileMaster::RadioProcesser do
  before do
    @processer = UserProfileMaster::RadioProcesser.new
    @master = stub_model(UserProfileMaster, :name => "master", :option_values => "select1,select2", :input_type => "radio")
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
  end
end

describe UserProfileMaster::InputTypeProcesser do
  before do
    @processer = UserProfileMaster::InputTypeProcesser.new
    @value = stub_model(UserProfileValue, :value => "value")
  end
  describe "#to_show_html" do
    it "valueの値が入っていること" do
      @processer.to_show_html(@value).should == "<div class=\"input_value\">value</div><div class=\"input_bottom\"></div>"
    end
  end
  describe "#to_edit_html" do
    it "正しいHTMLが生成されていること" do
      @processer.to_edit_html(stub_model(UserProfileMaster, :id => 1000), @value).should == "<input id=\"profile_value[1000]\" name=\"profile_value[1000]\" type=\"text\" value=\"value\" />"
    end
  end
  describe "#validate" do
    before do
      @master = stub_model(UserProfileMaster, :name => "master")
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "バリデーションエラーの場合" do
      it "バリデーションエラーが設定されること" do
        @master.stub!(:required).and_return(true)
        errors = mock('errors')
        errors.should_receive(:add_to_base).with("master は必須です")
        @value.stub!(:errors).and_return(errors)
        @processer.validate(@master, @value)
      end
    end
    describe "バリデーションエラーでない場合" do
      it "バリデーションエラーが設定されないこと" do
        @master.stub!(:required).and_return(false)
        @value.should_not_receive(:errors)
        @processer.validate(@master, @value)
      end
    end
  end
  describe "#option_value_validate" do
    before do
      @processer = UserProfileMaster::InputTypeProcesser.new
      @master = stub_model(UserProfileMaster, :name => "master", :option_values => "select1,select2", :input_type => "radio")
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "必須の場合" do
      before do
        @master.required = true
      end
      it "空の場合 必須です のバリデーションエラーになること" do
        @value.value = ""
        @value.should_not be_valid
        @value.errors.full_messages.first.should == "master は必須です"
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = "unselect"
        @value.should_not be_valid
        @value.errors.full_messages.first.should == "master は選択される値以外のものが設定されています"
      end
    end
    describe "必須でない場合" do
      before do
        @master.required = false
      end
      it "空の場合 何もバリデーションエラーにならないこと" do
        @value.value = ""
        @value.should be_valid
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = "unselect"
        @value.should_not be_valid
        @value.errors.full_messages.first.should == "master は選択される値以外のものが設定されています"
      end
    end
  end
end

describe UserProfileMaster::SelectProcesser do
  before do
    @processer = UserProfileMaster::SelectProcesser.new
    @master = stub_model(UserProfileMaster, :option_values => "select1,select2", :input_type => "select", :name => "master")
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
  end
  describe "#to_edit_html" do
    it "selectタグが含まれるhtmlが返ること" do
      @processer.to_edit_html(@master, @value).should have_tag("select")
    end
    it "データが存在している場合選択されていること" do
      @value.value = 'select2'
      @processer.to_edit_html(@master, @value).should have_tag("select") do
        with_tag("option[selected=selected]", "select2")
      end
    end
  end
end

describe UserProfileMaster::AppendableSelectProcesser do
  before do
    @processer = UserProfileMaster::AppendableSelectProcesser.new
    @master = stub_model(UserProfileMaster, :input_type => "appendable_select", :name => "master")
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    @values = (1..3).map{|i| "value#{i}"}
  end
  describe "#to_edit_html" do
    describe "既に登録されている値がある場合" do
      before do
        @processer.stub!(:registrated_select_option).with(@master).and_return(@values)
      end
      it "selectボックスが表示されていること" do
        @processer.to_edit_html(@master, @value).should have_tag("select") do
          with_tag("option", "value3")
        end
      end
      it "valueがselectボックスの値にある場合 selectボックスが選択されていること" do
        @value.value = "value1"
        @processer.to_edit_html(@master, @value).should have_tag("select") do
          with_tag("option[selected=selected]", "value1")
        end
      end
      it "text_fieldが表示されていること" do
        @processer.to_edit_html(@master, @value).should have_tag("input[type=text]")
      end
      it "valueがselectボックスの値に無い場合 text_field内に表示されていること" do
        @value.value = "text_input"
        @processer.to_edit_html(@master, @value).should have_tag("input[value=text_input]")
      end
    end
    describe "登録されている値が無い場合" do
      before do
        @processer.stub!(:registrated_select_option).and_return([])
      end
      it "selectボックスが表示されていないこと" do
        @processer.to_edit_html(@master, @value).should_not have_tag("select")
      end
      it "text_fieldが表示されていること" do
        @processer.to_edit_html(@master, @value).should have_tag("input[type=text]")
      end
    end
  end

  describe "#registrated_select_option" do
    before do
      @master = stub_model(UserProfileMaster, :option_values => "select1,select2", :input_type => "appendable_select", :name => "master")
    end
    describe "すべてのvalueに値が設定されている場合" do
      before do
        @registrated_values = (1..3).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value#{i}") }
      end
      it "requiredがtrueのとき valueの配列が返ってくること" do
        @master.required = true
        @processer.send(:registrated_select_option, @master).should == @registrated_values.map(&:value)
      end
      it "requiredがfalseのとき 先頭に空の入った配列が返ってくること" do
        @master.required = false
        @processer.send(:registrated_select_option, @master).should == @registrated_values.map(&:value).unshift("")
      end
    end
    describe "valueに空が設定されている場合" do
      before do
        @registrated_values = (1..3).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value#{i}") }
        @registrated_values << UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "")
      end
      it "requiredがtrueのとき 空が入っていないの配列が返ってくること" do
        @master.required = true
        @processer.send(:registrated_select_option, @master).should == ["value1", "value2", "value3"]
      end
      it "requiredがfalseのとき 先頭に空の入った配列が返ってくること" do
        @master.required = false
        @processer.send(:registrated_select_option, @master).should == ["", "value1", "value2", "value3"]
      end
    end
    describe "同じ値が複数個登録されている場合" do
      before do
        @registrated_values1 = (1..3).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value1") }
        @registrated_values2 = (1..7).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value2") }
        @registrated_values3 = (1..5).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value3") }
      end
      it "登録数が多い順に配列が並んでいること" do
        @master.required = true
        @processer.send(:registrated_select_option, @master).should == [ "value2", "value3", "value1"]
      end
    end
  end
end

describe UserProfileMaster::YearSelectProcesser do
  before do
    @processer = UserProfileMaster::YearSelectProcesser.new
  end
  describe "#validate" do
    before do
      @master = stub_model(UserProfileMaster, :name => "master", :option_values => "2007-2008")
    end
    describe "入力がない場合" do
      before do
        @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
      end
      describe "必須の場合" do
        before do
          @master.stub!(:required).and_return(true)
        end
        it "必須エラーが設定されること" do
          errors = mock('errors')
          errors.should_receive(:add_to_base).with("master は必須です")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
      describe "必須ではない場合" do
        before do
          @master.stub!(:required).and_return(false)
        end
        it "必須エラーが設定されないこと" do
          errors = mock('errors')
          errors.should_not_receive(:add_to_base).with("master は必須です")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
    end
    describe "入力がある場合" do
      describe "不正な年が入力されている場合" do
        before do
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "2006")
        end
        it "入力値が不正エラーが設定されること" do
          errors = mock('errors')
          errors.should_receive(:add_to_base).with("master は4桁の数値で入力して下さい")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
      describe "正しい年が入力されている場合" do
        before do
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "2007")
        end
        it "入力値が不正エラーが設定されないこと" do
          errors = mock('errors')
          errors.should_not_receive(:add_to_base).with("master は4桁の数値で入力して下さい")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
    end
  end

  describe "#max_year_and_min_year" do
    before do
      Time.now.stub!(:year).and_return(2008)
    end
    describe "引数が空の場合" do
      it { @processer.send!(:max_year_and_min_year, '').should == ['2008', '2008'] }
    end
    describe "引数が[2006]の場合" do
      it { @processer.send!(:max_year_and_min_year, '2006').should == ['2006', '2008'] }
    end
    describe "引数が[2006-]の場合" do
      it { @processer.send!(:max_year_and_min_year, '2006-').should == ['2006', '2008'] }
    end
    describe "引数が[2009-]の場合" do
      it { @processer.send!(:max_year_and_min_year, '2009-').should == ['2009', '2009'] }
    end
    describe "引数が[2006-2008]の場合" do
      it { @processer.send!(:max_year_and_min_year, '2006-2008').should == ['2006', '2008'] }
    end
    describe "引数が[2009-2006]の場合" do
      it { @processer.send!(:max_year_and_min_year, '2009-2006').should == ['2009', '2009'] }
    end
  end
end

describe UserProfileMaster::CheckBoxProcesser do
  before do
    @processer = UserProfileMaster::CheckBoxProcesser.new
  end
  describe "#to_edit_html" do
    before do
      @master = stub_model(UserProfileMaster, :option_values => "check1", :input_type => "check_box", :name => "master")
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "何も選択されていない場合" do
      it "checkboxのhtmlを返すこと" do
        @value.value = ""
        @processer.to_edit_html(@master, @value).should have_tag("input#profile_value_#{@master.id}_check1")
      end
    end
    describe "選択されていた場合" do
      it "checkedがcheckedなcheckboxのhtmlを返すこと" do
        @value.value = ["check1"]
        @value.save!
        @value.reload
        @processer.to_edit_html(@master, @value).should == "<input checked=\"checked\" id=\"profile_value_#{@master.id}_check1\" name=\"profile_value[#{@master.id}][]\" type=\"checkbox\" value=\"check1\" /><label for=\"profile_value_#{@master.id}_check1\">check1</label>"
      end
    end
    describe "validateを通っていない時" do
      it "checkedがcheckedなcheckboxのhtmlを返すこと" do
        @value.value = ["check1"]
        @processer.to_edit_html(@master, @value).should == "<input checked=\"checked\" id=\"profile_value_#{@master.id}_check1\" name=\"profile_value[#{@master.id}][]\" type=\"checkbox\" value=\"check1\" /><label for=\"profile_value_#{@master.id}_check1\">check1</label>"
      end
    end
  end
  describe "#validate" do
    before do
      @master = stub_model(UserProfileMaster, :option_values => "check1,check2,check3", :input_type => "check_box", :name => "master", :required => true)
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "必須の場合" do
      it "空の場合 必須です のバリデーションエラーになること" do
        @value.value = []
        @value.should_not be_valid
        @value.errors.full_messages.first.should == "master は必須です"
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = ["uncheck","check1"]
        @value.should_not be_valid
        @value.errors.full_messages.first.should == "master は選択される値以外のものが設定されています"
      end
      it "正しい項目が入っている場合 バリデーションエラーにならないこと" do
        @value.value = ["check1","check2","check3"]
        @value.should be_valid
      end
    end
    describe "必須でない場合" do
      before do
        @master.required = false
      end
      it "空の場合 何もバリデーションエラーにならないこと" do
        @value.value = nil
        @value.should be_valid
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = ["uncheck"]
        @value.should_not be_valid
        @value.errors.full_messages.first.should == "master は選択される値以外のものが設定されています"
      end
    end
    it "文字列が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
      @value.value = "uncheck"
      @value.should_not be_valid
      @value.errors.full_messages.first.should == "master に不正な形式が設定されています"
    end
  end
end

describe UserProfileMaster::PrefectureSelectProcesser do
  before do
    @processer = UserProfileMaster::PrefectureSelectProcesser.new
  end
  describe "#validate" do
    before do
      @master = stub_model(UserProfileMaster, :name => "master")
    end
    describe "入力がない場合" do
      before do
        @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
      end
      describe "必須の場合" do
        before do
          @master.stub!(:required).and_return(true)
        end
        it "必須エラーが設定されること" do
          errors = mock('errors')
          errors.should_receive(:add_to_base).with("master は必須です")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
      describe "必須ではない場合" do
        before do
          @master.stub!(:required).and_return(false)
        end
        it "必須エラーが設定されないこと" do
          errors = mock('errors')
          errors.should_not_receive(:add_to_base).with("master は必須です")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
        it "入力値不正エラーが設定されないこと" do
          errors = mock('errors')
          errors.should_not_receive(:add_to_base).with("master は選択される値以外のものが設定されています")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
    end
    describe "入力がある場合" do
      describe "不正なPrefectureが入力されている場合" do
        before do
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "存在しない県")
        end
        it "入力値が不正エラーが設定されること" do
          errors = mock('errors')
          errors.should_receive(:add_to_base).with("master は選択される値以外のものが設定されています")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
      describe "正しいPrefectureが入力されている場合" do
        before do
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "北海道")
        end
        it "入力値が不正エラーが設定されないこと" do
          errors = mock('errors')
          errors.should_not_receive(:add_to_base).with("master は選択される値以外のものが設定されています")
          @value.stub!(:errors).and_return(errors)
          @processer.validate(@master, @value)
        end
      end
    end
  end
end

describe UserProfileMaster::DatePickerProcesser do
  before do
    @processer = UserProfileMaster::DatePickerProcesser.new
  end
  describe "#validate" do
    before do
      @master = stub_model(UserProfileMaster, :name => "master")
      @errors = mock('errors')
      @errors.stub!(:add_to_base)
    end
    describe "入力がない場合" do
      before do
        @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
      end
      describe "必須の場合" do
        before do
          @master.stub!(:required).and_return(true)
        end
        it "必須エラーが設定されること" do
          @errors.should_receive(:add_to_base).with("master は必須です")
          @value.stub!(:errors).and_return(@errors)
          @processer.validate(@master, @value)
        end
      end
      describe "必須ではない場合" do
        before do
          @master.stub!(:required).and_return(false)
        end
        it "エラーが設定されないこと" do
          @errors.should_not_receive(:add_to_base)
          @value.stub!(:errors).and_return(@errors)
          @processer.validate(@master, @value)
        end
      end
    end
    describe "入力がある場合" do
      describe "妥当な日付の場合" do
        before do
          @input_date = "2008/11/11"
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => @input_date)
        end
        it "日付妥当性チェックエラーが設定されないこと" do
          @errors.should_not_receive(:add_to_base).with("master は正しい日付形式で入力して下さい")
          @value.stub!(:errors).and_return(@errors)
          @processer.validate(@master, @value)
        end
      end
      describe "妥当だが、西暦が未指定の日付場合" do
        before do
          @input_date = "11/11"
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => @input_date)
        end
        it "日付妥当性チェックエラーが設定されないこと" do
          @errors.should_not_receive(:add_to_base).with("master は正しい日付形式で入力して下さい")
          @value.stub!(:errors).and_return(@errors)
          @processer.validate(@master, @value)
        end
        it "西暦が補完されること" do
          lambda do
            @processer.validate(@master, @value)
          end.should change(@value, :value).from(@input_date).to("#{Time.now.year}/#{@input_date}")
        end
      end
      describe "妥当ではない日付の場合" do
        describe "範囲外の場合" do
          before do
            @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "2008/13/1")
          end
          it "日付妥当性チェックエラーが設定されること" do
            @errors.should_receive(:add_to_base).with("master は正しい日付形式で入力して下さい")
            @value.stub!(:errors).and_return(@errors)
            @processer.validate(@master, @value)
          end
        end
        describe "フォーマットが不正な場合" do
          before do
            @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "2008,12,1")
          end
          it "日付妥当性チェックエラーが設定されること" do
            @errors.should_receive(:add_to_base).with("master は正しい日付形式で入力して下さい")
            @value.stub!(:errors).and_return(@errors)
            @processer.validate(@master, @value)
          end
        end
      end
    end
  end
end


describe UserProfileMaster, "#sort_order" do
  before do
    (1..10).each{|i| create_user_profile_master(:name => SkipFaker.rand_char, :sort_order => SkipFaker.rand_num, :input_type => "text_field")}
  end
  it "複数件検索した場合に、sort_orderの順で並んでいること" do
    raw = UserProfileMaster.all.map{|master| master.sort_order}
    raw.sort.should == raw
  end
end
