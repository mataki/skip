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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::GroupCategoriesController, 'DELETE /destroy' do
  before do
    admin_login
  end
  describe '対象のgroup_categoryが存在する場合' do
    before do
      @group_category = stub_model(Admin::GroupCategory)
      @group_category.stub!(:deletable?)
      Admin::GroupCategory.stub!(:find).and_return(@group_category)
    end
    describe '削除可能な場合' do
      before do
        @group_category.should_receive(:deletable?).and_return(true)
        @group_category.should_receive(:destroy)
        delete :destroy
      end
      it { flash[:notice].should_not be_nil }
      it { response.should redirect_to(admin_group_categories_path) }
    end
    describe '削除不可能な場合' do
      before do
        @group_category.should_receive(:deletable?).and_return(false)
        @group_category.should_not_receive(:destroy)
        mock_errors = mock('errors')
        mock_errors.should_receive(:full_messages).and_return(['error'])
        @group_category.stub!(:errors).and_return(mock_errors)
        delete :destroy
      end
      it { flash[:error].should_not be_nil }
      it { response.should redirect_to(admin_group_categories_path) }
    end
  end
  describe '対象のgroup_categoryが存在しない場合' do
    before do
      @group_category = stub_model(Admin::GroupCategory)
      Admin::GroupCategory.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)
      delete :destroy
    end
    it { flash[:error].should_not be_nil }
    it { response.should redirect_to(admin_group_categories_path) }
  end
end
