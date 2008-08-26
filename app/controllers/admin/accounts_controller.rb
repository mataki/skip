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

class Admin::AccountsController < Admin::ApplicationController
  include AdminModule::AdminRootModule

  def import
    if request.get? || !valid_csv?(params[:file])
      @accounts = []
      return
    end
    @accounts = Admin::Account.make_accounts(params[:file])
    Admin::Account.transaction do
      @accounts.each do |account|
        account.save!
      end
    end
    flash[:notice] = _('CSVファイルからのアカウント登録/更新に成功しました。')
    redirect_to admin_accounts_path
  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotSaved => e
    flash[:error] = _('CSVファイルに不正な値が含まれています。')
    @accounts.each {|account| account.valid?}
  end

  private
  def valid_csv?(uploaded_file)
    if uploaded_file.blank?
      flash[:error] = _('ファイルを指定して下さい。')
      return false
    end

    if uploaded_file.size == 0
      flash[:error] = _('ファイルサイズが0です。')
      return false
    end

    if uploaded_file.size > 1.megabyte
      flash[:error] = _('ファイルサイズが1MBを超えています。')
      return false
    end

    unless ['text/csv', 'application/x-csv'].include?(uploaded_file.content_type)
      flash[:error] = _('csvファイル以外はアップロード出来ません。')
      return false
    end
    true
  end
end
