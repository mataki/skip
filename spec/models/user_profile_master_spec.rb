# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

describe UserProfileMaster, 'validation' do
  describe UserProfileMaster, '.validates_presence_of_category' do
    describe 'user_profile_master_categoryに対象のカテゴリが存在する場合' do
      before do
        @user_profile_master = create_user_profile_master(:user_profile_master_category_id => create_user_profile_master_category.id)
      end
      it 'validationに成功すること' do
        @user_profile_master.send(:validates_presence_of_category).should be_true
      end
    end
    describe 'user_profile_master_categoryに対象のカテゴリが存在しない場合' do
      before do
        @user_profile_master = create_user_profile_master
      end
      it 'validationに失敗すること' do
        @user_profile_master.send(:validates_presence_of_category).should be_false
      end
      it 'エラーメッセージが設定されること' do
        lambda do
          @user_profile_master.send(:validates_presence_of_category)
        end.should change(@user_profile_master.errors, :size).from(0).to(1)
      end
    end
  end
end

describe UserProfileMaster, "#input_type_processer" do
  it "input_typeがtext_fieldの場合、TextFieldのインスタンスが返ってくること" do
    @master = create_user_profile_master(:input_type => "text_field")
    @master.input_type_processer.should be_is_a(UserProfileMaster::TextFieldProcesser)
  end
end

describe UserProfileMaster, ".input_type_option" do
  it "セレクトボックス用の配列が返ってくること" do
    UserProfileMaster.input_type_option.size.should == 10
  end
  it "順番通りに返ってくること" do
    valid_option = [["Text box", "text_field"],
                    ["Number and hyphen", "number_and_hyphen_only"],
                    ["Rich text", "rich_text"],
                    ["Check box", "check_box"],
                    ["Radio button", "radio"],
                    ["Drop-down list", "select"],
                    ["Appendable selection list", "appendable_select"],
                    ["Prefecture selection", "prefecture_select"],
                    ["Year selection", "year_select"],
                    ["Date picker", "datepicker"]]
    UserProfileMaster.input_type_option.should == valid_option
  end
end

describe UserProfileMaster, ".input_type_processer_class" do
  it "存在する(text_field)が渡された場合 相当するプロセッサーのクラスを返すこと" do
    UserProfileMaster.input_type_processer_class('text_field').should == UserProfileMaster::TextFieldProcesser
  end
  it "存在しない(hoge_field)が渡された場合 InputTypeProcesserのクラスを返すこと" do
    UserProfileMaster.input_type_processer_class('hoge_field').should == UserProfileMaster::InputTypeProcesser
  end
end

describe UserProfileMaster::InputTypeProcesser do
  before do
    @master = stub_model(UserProfileMaster, :name => "master")
    @processer = UserProfileMaster::InputTypeProcesser.new(@master)
    @value = stub_model(UserProfileValue, :value => "value")
  end
  describe "#to_edit_html" do
    it "正しいHTMLが生成されていること" do
      @master.id = 1000
      @processer.to_edit_html(@value).should == "<input id=\"profile_value_1000\" name=\"profile_value[1000]\" type=\"text\" value=\"value\" />"
    end
  end
  describe "#validate" do
    before do
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "バリデーションエラーの場合" do
      before do
        @master.required = true
      end
      it "バリデーションエラーが設定されること" do
        @processer.validate(@value)
        @value.errors.full_messages.first.should == 'master is mandatory.'
      end
    end
    describe "バリデーションエラーでない場合" do
      before do
        @master.required = false
      end
      it "バリデーションエラーが設定されないこと" do
        @processer.validate(@value)
        @value.errors.should be_empty
      end
    end
  end
  describe "#option_value_validate" do
    before do
      @master = stub_model(UserProfileMaster, :name => "master", :option_values => "select1,select2", :input_type => "hoge")
      @processer = UserProfileMaster::InputTypeProcesser.new(@master)
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "必須の場合" do
      before do
        @master.required = true
      end
      it "空の場合 必須です のバリデーションエラーになること" do
        @value.value = ""
        @processer.option_value_validate(@value)
        @value.errors.full_messages.first.should == "master is mandatory."
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = "unselect"
        @processer.option_value_validate(@value)
        @value.errors.full_messages.first.should == "master contains value not in selectable options."
      end
    end
    describe "必須でない場合" do
      before do
        @master.required = false
      end
      it "空の場合 何もバリデーションエラーにならないこと" do
        @value.value = ""
        @processer.option_value_validate(@value)
        @value.errors.should be_empty
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = "unselect"
        @processer.option_value_validate(@value)
        @value.errors.full_messages.first.should == "master contains value not in selectable options."
      end
    end
  end
  describe '#validates_presence_of_option_values' do
    before do
      @master = stub_model(UserProfileMaster, :name => "master", :option_values => "", :input_type => 'text_field')
      @processer = UserProfileMaster::InputTypeProcesser.new(@master)
      @errors = mock('errors')
      @errors.stub!(:clear)
      @master.stub!(:errors).and_return(@errors)
    end
    describe 'option_valuesが必須の場合' do
      before do
        @processer.class.should_receive(:need_option_values?).and_return(true)
      end
      describe 'option_valuesに入力がある場合' do
        before do
          @master.option_values = 'skip'
        end
        it 'masterにoption_valuesのバリデーションエラーが設定されないこと' do
          @errors.should_not_receive(:add).with(:option_values, "は必須です。")
          @processer.validates_presence_of_option_values
        end
      end
      describe 'option_valuesに入力がない場合' do
        before do
          @master.option_values = ''
        end
        it 'masterにoption_valuesが必須である旨のバリデーションエラーが設定されること' do
          @errors.should_receive(:add).with(:option_values, "is mandatory.")
          @processer.validates_presence_of_option_values
        end
      end
    end
    describe 'option_valuesが必須ではない場合' do
      before do
        @processer.class.should_receive(:need_option_values?).and_return(false)
      end
      it 'masterにoption_valuesのバリデーションエラーが設定されないこと' do
        @errors.should_not_receive(:add).with(:option_values, "は必須です。")
        @processer.validates_presence_of_option_values
      end
    end
  end
end

describe UserProfileMaster::NumberAndHyphenOnlyProcesser do
  describe '#validate' do
    before do
      @master = stub_model(UserProfileMaster, :name => "master", :input_type => 'number_and_hyphen_only')
      @processer = UserProfileMaster::NumberAndHyphenOnlyProcesser.new(@master)
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe '入力がない場合' do
      before do
        @value.value = ''
      end
      describe '必須の場合' do
        before do
          @master.required = true
        end
        it '必須エラーになること' do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "master is mandatory."
        end
      end
      describe '必須ではない場合' do
        before do
          @master.required = false
        end
        it 'エラーにならないこと' do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
    end
    describe '入力がある場合' do
      describe '数値とハイフンのみの場合' do
        before do
          @value.value = '123-'
        end
        it 'エラーにならないこと' do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
      describe '数値とハイフン以外が含まれる場合' do
        before do
          @value.value = 'hoge'
        end
        it 'フォーマットエラーとなること' do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "master accepts numbers and hiphens(\"-\") only."
        end
      end
    end
  end
end

describe UserProfileMaster::RadioProcesser do
  before do
    @master = stub_model(UserProfileMaster, :name => "master", :option_values => "select1,select2", :input_type => "radio")
    @processer = UserProfileMaster::RadioProcesser.new(@master)
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
  end
end

describe UserProfileMaster::YearSelectProcesser do
  before do
    @master = stub_model(UserProfileMaster, :name => "master", :option_values => "2007-2008")
    @processer = UserProfileMaster::YearSelectProcesser.new(@master)
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
  end
  describe "#validate" do
    describe "入力がない場合" do
      before do
        @value.value = ''
      end
      describe "必須の場合" do
        before do
          @master.stub!(:required).and_return(true)
        end
        it "必須エラーが設定されること" do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "master is mandatory."
        end
      end
      describe "必須ではない場合" do
        before do
          @master.required = false
        end
        it "必須エラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
    end
    describe "入力がある場合" do
      describe "不正な年が入力されている場合" do
        before do
          @value.value = '206'
        end
        it "入力値が不正エラーが設定されること" do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "Enter master in 4-digit numbers."
        end
      end
      describe "正しい年が入力されている場合" do
        before do
          @value.value = '2007'
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "2007")
        end
        it "入力値が不正エラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
    end
  end

  describe '#validates_format_of_option_values' do
    before do
      @master = UserProfileMaster.new(:name => "master", :option_values => "")
      @processer = UserProfileMaster::YearSelectProcesser.new(@master)
    end
    describe '入力がない場合' do
      before do
        @master.option_values = ''
      end
      it 'フォーマットエラーが設定されないこと' do
        @processer.validates_format_of_option_values
        @master.errors.should be_empty
      end
    end

    describe '入力がある場合' do
      describe '数値とハイフンの文字列の場合' do
        before do
          @master.option_values = "2007-2008"
        end
        it 'フォーマットエラーが設定されないこと' do
          @processer.validates_format_of_option_values
          @master.errors.should be_empty
        end
      end
      describe '数値とハイフン以外の文字列が含まれる場合' do
        before do
          @master.option_values = "2007,2008"
        end
        it 'フォーマットエラーが設定されること' do
          @processer.validates_format_of_option_values
          @master.errors.full_messages.first.should == "Option values accepts numbers and hiphens(\"-\") only."
        end
      end
    end
  end

  describe "#start_year_and_end_year" do
    before do
      Time.stub!(:now).and_return(Time.local(2008))
    end
    describe "引数が空の場合" do
      it { @processer.send(:start_year_and_end_year, '').should == ['2008', '2008'] }
    end
    describe "引数が[2006]の場合" do
      it { @processer.send(:start_year_and_end_year, '2006').should == ['2006', '2008'] }
    end
    describe "引数が[2006-]の場合" do
      it { @processer.send(:start_year_and_end_year, '2006-').should == ['2006', '2008'] }
    end
    describe "引数が[2009-]の場合" do
      it { @processer.send(:start_year_and_end_year, '2009-').should == ['2009', '2008'] }
    end
    describe "引数が[-2006]の場合" do
      it { @processer.send(:start_year_and_end_year, '-2006').should == ['2008', '2006'] }
    end
    describe "引数が[-2009]の場合" do
      it { @processer.send(:start_year_and_end_year, '-2009').should == ['2008', '2009'] }
    end
    describe "引数が[2006-2008]の場合" do
      it { @processer.send(:start_year_and_end_year, '2006-2008').should == ['2006', '2008'] }
    end
    describe "引数が[2009-2006]の場合" do
      it { @processer.send(:start_year_and_end_year, '2009-2006').should == ['2009', '2006'] }
    end
  end
end

describe UserProfileMaster::SelectProcesser, :type => :view do
  before do
    @master = stub_model(UserProfileMaster, :option_values => "select1,select2", :input_type => "select", :name => "master")
    @processer = UserProfileMaster::SelectProcesser.new(@master)
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
  end
  describe "#to_edit_html" do
    it "selectタグが含まれるhtmlが返ること" do
      @processer.to_edit_html(@value).should have_tag("select")
    end
    it "データが存在している場合選択されていること" do
      @value.value = 'select2'
      @processer.to_edit_html(@value).should have_tag("select") do
        with_tag("option[selected=selected]", "select2")
      end
    end
  end
end

describe UserProfileMaster::AppendableSelectProcesser, :type => :view do
  before do
    @master = stub_model(UserProfileMaster, :input_type => "appendable_select", :name => "master")
    @processer = UserProfileMaster::AppendableSelectProcesser.new(@master)
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    @values = (1..3).map{|i| "value#{i}"}
  end
  describe "#to_edit_html" do
    describe "既に登録されている値がある場合" do
      before do
        @processer.stub!(:registrated_select_option).and_return(@values)
      end
      it "selectボックスが表示されていること" do
        @processer.to_edit_html(@value).should have_tag("select") do
          with_tag("option", "value3")
        end
      end
      it "valueがselectボックスの値にある場合 selectボックスが選択されていること" do
        @value.value = "value1"
        @processer.to_edit_html(@value).should have_tag("select") do
          with_tag("option[selected=selected]", "value1")
        end
      end
      it "text_fieldが表示されていること" do
        @processer.to_edit_html(@value).should have_tag("input[type=text]")
      end
      it "valueがselectボックスの値に無い場合 text_field内に表示されていること" do
        @value.value = "text_input"
        @processer.to_edit_html(@value).should have_tag("input[value=text_input]")
      end
    end
    describe "登録されている値が無い場合" do
      before do
        @processer.stub!(:registrated_select_option).and_return([])
      end
      it "selectボックスが表示されていないこと" do
        @processer.to_edit_html(@value).should_not have_tag("select")
      end
      it "text_fieldが表示されていること" do
        @processer.to_edit_html(@value).should have_tag("input[type=text]")
      end
    end
  end

  describe "#registrated_select_option" do
    before do
      @master.option_values = "select1,select2"
    end
    describe "すべてのvalueに値が設定されている場合" do
      before do
        @registrated_values = (1..3).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value#{i}") }
      end
      it "requiredがtrueのとき valueの配列が返ってくること" do
        @master.required = true
        @processer.send(:registrated_select_option).should == @registrated_values.map(&:value)
      end
      it "requiredがfalseのとき 先頭に空の入った配列が返ってくること" do
        @master.required = false
        @processer.send(:registrated_select_option).should == @registrated_values.map(&:value).unshift("")
      end
    end
    describe "valueに空が設定されている場合" do
      before do
        @registrated_values = (1..3).map{|i| UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "value#{i}") }
        @registrated_values << UserProfileValue.create!(:user_profile_master => @master, :user => mock_model(User), :value => "")
      end
      it "requiredがtrueのとき 空が入っていないの配列が返ってくること" do
        @master.required = true
        @processer.send(:registrated_select_option).should == ["value1", "value2", "value3"]
      end
      it "requiredがfalseのとき 先頭に空の入った配列が返ってくること" do
        @master.required = false
        @processer.send(:registrated_select_option).should == ["", "value1", "value2", "value3"]
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
        @processer.send(:registrated_select_option).should == [ "value2", "value3", "value1"]
      end
    end
  end
end

describe UserProfileMaster::CheckBoxProcesser, :type => :view do
  before do
    @master = stub_model(UserProfileMaster, :option_values => "check1", :input_type => "check_box", :name => "master")
    @processer = UserProfileMaster::CheckBoxProcesser.new(@master)
  end
  describe "#to_edit_html" do
    before do
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "何も選択されていない場合" do
      it "checkboxのhtmlを返すこと" do
        @value.value = ""
        @processer.to_edit_html(@value).should have_tag("input#profile_value_#{@master.id}_check1")
      end
    end
    describe "選択されていた場合" do
      before do
        @value.value = "check1"
      end
      it "checkedがcheckedなcheckboxのhtmlを返すこと" do
        @processer.to_edit_html(@value).should == "<input checked=\"checked\" id=\"profile_value_#{@master.id}_check1\" name=\"profile_value[#{@master.id}][]\" type=\"checkbox\" value=\"check1\" /><label for=\"profile_value_#{@master.id}_check1\">check1</label>"
      end
    end
    describe "validateを通っていない時" do
      it "checkedがcheckedなcheckboxのhtmlを返すこと" do
        @value.value = "check1"
        @processer.to_edit_html(@value).should == "<input checked=\"checked\" id=\"profile_value_#{@master.id}_check1\" name=\"profile_value[#{@master.id}][]\" type=\"checkbox\" value=\"check1\" /><label for=\"profile_value_#{@master.id}_check1\">check1</label>"
      end
    end
  end
  describe "#validate" do
    before do
      @master = stub_model(UserProfileMaster, :option_values => "check1,check2,check3", :input_type => "check_box", :name => "master", :required => true)
      @processer = UserProfileMaster::CheckBoxProcesser.new(@master)
      @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
    end
    describe "必須の場合" do
      it "空の場合 必須です のバリデーションエラーになること" do
        @value.value = ''
        @processer.validate(@value)
        @value.errors.full_messages.first.should == "master is mandatory."
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = ["uncheck","check1"]
        @processer.validate(@value)
        @value.errors.full_messages.first.should == "master contains value not in selectable options."
      end
      it "正しい項目が入っている場合 バリデーションエラーにならないこと" do
        @value.value = ["check1","check2","check3"]
        @processer.validate(@value)
        @value.errors.should be_empty
      end
    end
    describe "必須でない場合" do
      before do
        @master.required = false
      end
      it "空の場合 何もバリデーションエラーにならないこと" do
        @value.value = nil
        @processer.validate(@value)
        @value.errors.should be_empty
      end
      it "選択される項目以外の値が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
        @value.value = ["uncheck"]
        @processer.validate(@value)
        @value.errors.full_messages.first.should == "master contains value not in selectable options."
      end
    end
    it "文字列が入っている場合 選択される値以外の値が設定されていますというバリデーションエラーになること" do
      @value.value = "uncheck"
      @processer.validate(@value)
      @value.errors.full_messages.first.should == "Invalid format for master."
    end
  end
  describe "#before_save" do
    describe "正しい項目が入力されている場合" do
      before do
        @master = stub_model(UserProfileMaster, :option_values => "check1,check2,check3", :input_type => "check_box", :name => "master")
        @input_value = ["check1", "check2", "check3"]
        @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => @input_value)
      end
      it "カンマ区切りの文字列に変換されること" do
        expect_value = "check1,check2,check3"
        lambda do
          @processer.before_save(@value)
        end.should change(@value, :value).from(@input_value).to(expect_value)
      end
    end
  end
end

describe UserProfileMaster::PrefectureSelectProcesser, :type => :view do
  before do
    @master = stub_model(UserProfileMaster, :name => "master")
    @processer = UserProfileMaster::PrefectureSelectProcesser.new(@master)
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
  end
  describe "#validate" do
    describe "入力がない場合" do
      before do
        @value.value = ''
      end
      describe "必須の場合" do
        before do
          @master.required = true
        end
        it "必須エラーが設定されること" do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "master is mandatory."
        end
      end
      describe "必須ではない場合" do
        before do
          @master.required = false
        end
        it "必須エラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
    end
    describe "入力がある場合" do
      describe "不正なPrefectureが入力されている場合" do
        before do
          @value.value = "存在しない県"
        end
        it "入力値が不正エラーが設定されること" do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "master contains value not in selectable options."
        end
      end
      describe "正しいPrefectureが入力されている場合" do
        before do
          @value.value = "北海道"
        end
        it "入力値が不正エラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
    end
  end
end

describe UserProfileMaster::DatepickerProcesser, :type => :view do
  before do
    @master = stub_model(UserProfileMaster, :name => "master")
    @processer = UserProfileMaster::DatepickerProcesser.new(@master)
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
  end
  describe "#validate" do
    describe "入力がない場合" do
      before do
        @value.value = ''
      end
      describe "必須の場合" do
        before do
          @master.required = true
        end
        it "必須エラーが設定されること" do
          @processer.validate(@value)
          @value.errors.full_messages.first.should == "master is mandatory."
        end
      end
      describe "必須ではない場合" do
        before do
          @master.required = false
        end
        it "エラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
    end
    describe "入力がある場合" do
      describe "妥当な日付の場合" do
        before do
          @value.value = "2008/11/11"
        end
        it "日付妥当性チェックエラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
      describe "妥当だが、西暦が未指定の日付場合" do
        before do
          @value.value = "11/11"
        end
        it "日付妥当性チェックエラーが設定されないこと" do
          @processer.validate(@value)
          @value.errors.should be_empty
        end
      end
      describe "妥当ではない日付の場合" do
        describe "範囲外の場合" do
          before do
            @value.value = "2008/13/1"
          end
          it "日付妥当性チェックエラーが設定されること" do
            @processer.validate(@value)
            @value.errors.full_messages.first.should == "Enter master in a valid date format."
          end
        end
        describe "フォーマットが不正な場合" do
          before do
            @value.value = "2008,12,1"
          end
          it "日付妥当性チェックエラーが設定されること" do
            @processer.validate(@value)
            @value.errors.full_messages.first.should == "Enter master in a valid date format."
          end
        end
      end
    end
  end

  describe "#before_save" do
    before do
      @master = stub_model(UserProfileMaster, :name => "master")
    end
    describe "入力がある場合" do
      before do
        @input_date = "2008-11-11"
        @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => @input_date)
      end
      describe "妥当な日付の場合" do
        it "日付の形式が/区切りになっていること" do
          expect_date = "2008/11/11"
          lambda do
            @processer.before_save(@value)
          end.should change(@value, :value).from(@input_date).to(expect_date)
        end
      end
      describe "妥当だが、西暦が未指定の日付場合" do
        before do
          @input_date = "11/11"
          @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => @input_date)
        end
        it "西暦が補完されること" do
          lambda do
            @processer.before_save(@value)
          end.should change(@value, :value).from(@input_date).to("#{Time.now.year}/#{@input_date}")
        end
      end
    end
    describe "入力が無い場合" do
      before do
        @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User), :value => "")
      end
      it "空のまま登録されること" do
        lambda do
          @processer.before_save(@value)
        end.should_not change(@value, :value)
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
