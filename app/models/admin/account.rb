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

class Admin::Account < Account
  require 'fastercsv'

  N_('Admin::Account|Code')
  N_('Admin::Account|Name')
  N_('Admin::Account|Email')
  N_('Admin::Account|Section')
  N_('Admin::Account|Password')
  N_('Admin::Account|Password confirmation')

  def self.search_colomns
    "code like :lqs or name like :lqs or email like :lqs or section like :lqs"
  end

  def self.make_accounts(uploaded_file)
    accounts = []
    parsed_csv = FasterCSV.parse uploaded_file
    parsed_csv.each do |line|
      accounts << make_account(line)
    end
    accounts
  end

  private
  def self.make_account(line)
    account_hash = {:code => line[0], :name => line[1], :email => line[3], :section => line[2], :password => line[4], :password_confirmation => line[4]}
    account = Admin::Account.find_by_code(line[0])
    if account
      account.attributes = account_hash
    else
      account = Admin::Account.new(account_hash)
    end
    account
  end
end
