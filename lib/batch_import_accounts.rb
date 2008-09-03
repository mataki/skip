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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require "csv"

class BatchImportAccounts < BatchBase
  csv = CSV.readlines('accounts.csv', "\n")
  csv.each do |line|
    begin
      User.transaction do
        user = User.new( :name => line[1], :section => line[2], :email => line[3],
                         :password => line[4], :password_confirmation => line[4], :status => 'UNUSED' )
        user.user_uids << UserUid.new( :uid => line[0], :uid_type => 'MASTER' )
        user.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      puts "#{line[0]} - #{line[1]}は既に登録されているか、重複項目があるため登録されませんでした"
    end
  end
end
