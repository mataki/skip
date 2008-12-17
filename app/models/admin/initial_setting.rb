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

class Admin::InitialSetting < ActiveRecord::Base
  # ================================================================================================
  # 共有ファイル関連
  # ================================================================================================
  N_('Admin::InitialSetting|Max share file size')
  N_('Admin::InitialSetting|Max share file size description')
  N_('Admin::InitialSetting|Max share file size per owner')
  N_('Admin::InitialSetting|Max share file size per owner description')
  N_('Admin::InitialSetting|Max share file size of system')
  N_('Admin::InitialSetting|Max share file size of system description')

  # ================================================================================================
  # アカウント関連
  # ================================================================================================
  N_('Admin::InitialSetting|Login mode')
  N_('Admin::InitialSetting|Login mode description')
  N_('Admin::InitialSetting|Login mode|password')
  N_('Admin::InitialSetting|Login mode|rp')
  N_('Admin::InitialSetting|Usercode dips setting')
  N_('Admin::InitialSetting|Usercode dips setting description')
  N_('Admin::InitialSetting|Usercode dips setting|true')
  N_('Admin::InitialSetting|Usercode dips setting|false')
  N_('Admin::InitialSetting|Password edit setting')
  N_('Admin::InitialSetting|Password edit setting description')
  N_('Admin::InitialSetting|Password edit setting|true')
  N_('Admin::InitialSetting|Password edit setting|false')
  N_('Admin::InitialSetting|Username use setting')
  N_('Admin::InitialSetting|Username use setting description')
  N_('Admin::InitialSetting|Username use setting|true')
  N_('Admin::InitialSetting|Username use setting|false')
  N_('Admin::InitialSetting|User code format regex')
  N_('Admin::InitialSetting|User code format regex description')
  N_('Admin::InitialSetting|User code minimum length')
  N_('Admin::InitialSetting|User code minimum length description')

  # ================================================================================================
  # 機能に関する設定
  # ================================================================================================
  N_('Admin::InitialSetting|Ssl setting')
  N_('Admin::InitialSetting|Ssl setting description')
  N_('Admin::InitialSetting|Ssl setting|true')
  N_('Admin::InitialSetting|Ssl setting|false')
  N_('Admin::InitialSetting|Full text search setting')
  N_('Admin::InitialSetting|Full text search setting description')
  N_('Admin::InitialSetting|Full text search setting|true')
  N_('Admin::InitialSetting|Full text search setting|false')
  N_('Admin::InitialSetting|Proxy url')
  N_('Admin::InitialSetting|Proxy url description')

  # ================================================================================================
  # システム運用について
  # ================================================================================================
  N_('Admin::InitialSetting|Administrator addr')
  N_('Admin::InitialSetting|Administrator addr description')
end
