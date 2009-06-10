# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

class GroupCategory < ActiveRecord::Base
  has_many :groups, :conditions => 'groups.deleted_at IS NULL'

  N_('GroupCategory|Initial selected|true')
  N_('GroupCategory|Initial selected|false')

  ICONS = ['group_gear', 'ipod', 'joystick', 'money', 'music', 'page_excel', 'page_word', 'phone', 'ruby', 'tux']

  validates_presence_of :code
  validates_uniqueness_of :code, :case_sensitive => false
  validates_length_of :code, :maximum => 20
  validates_format_of :code, :message => _('はアルファベットで入力して下さい。'), :with => /^[a-zA-Z]*$/

  validates_presence_of :name
  validates_length_of :name, :maximum => 20

  validates_presence_of :icon
  validates_inclusion_of :icon, :in => ICONS

  validates_length_of :description, :maximum => 255

  def before_save
    if self.initial_selected
      if initial_selected_group_category = self.class.find_by_initial_selected(true)
        if self.new_record? || !(self.id == initial_selected_group_category.id)
          initial_selected_group_category.toggle!(:initial_selected)
        end
      end
    end
  end

  def deletable?
    if self.initial_selected?
      errors.add_to_base(_('対象のカテゴリはグループ作成時に初期選択される設定のため削除出来ません。'))
      return false
    else
      unless self.groups.empty?
        errors.add_to_base(_('対象のカテゴリのグループが存在するため削除できません。'))
        return false
      end
    end
    true
  end
end
