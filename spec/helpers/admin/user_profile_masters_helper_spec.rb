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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UserProfileMastersHelper do

  #Delete this example and add some real ones or delete this file
  it "should be included in the object returned by #helper" do
    included_modules = (class << helper; self; end).send :included_modules
    included_modules.should include(Admin::UserProfileMastersHelper)
  end

  describe "option_values_help_icon_hash_as_json" do
    it "正しい形式のjsonが返ってくること" do
      helper.option_values_help_icon_hash_as_json.should be_include("Provide the candidates in comma separated format (e.g. Movie,Sports,Internet).")
    end
  end

  describe "option_values_need_hash_as_json" do
    before do
      UserProfileMaster.stub!(:input_types).and_return(%w(text_field))
    end
    it "正しい形式のjsonが返ってくること" do
      helper.option_values_need_hash_as_json.should == {"text_field" => false}.to_json
    end
  end
end
