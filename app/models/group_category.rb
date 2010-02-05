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

class GroupCategory < ActiveRecord::Base
  belongs_to :tenant
  has_many :groups, :conditions => 'groups.deleted_at IS NULL'

  N_('GroupCategory|Initial selected|true')
  N_('GroupCategory|Initial selected|false')

  ICONS = ['group_gear', 'ipod', 'joystick', 'money', 'music', 'page_excel', 'page_word', 'phone', 'ruby', 'tux']

  validates_presence_of :code
  validates_uniqueness_of :code, :case_sensitive => false
  validates_length_of :code, :maximum => 20
  validates_format_of :code, :message => _('accepts alphabet (a-z, A-Z) only.'), :with => /^[a-zA-Z]*$/

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
      errors.add_to_base(_('Category could not be deleted since it is set to be selected by default upon group creation.'))
      return false
    else
      unless self.groups.empty?
        errors.add_to_base(_('Category could not be deleted due to groups belonging to itself.'))
        return false
      end
    end
    true
  end

  named_scope :with_groups_count, proc { |user|
    if user
      { :conditions => ['group_participations.user_id = ? AND groups.deleted_at IS NULL', user.id],
        :joins => 'LEFT JOIN groups ON group_categories.id = groups.group_category_id LEFT JOIN group_participations ON groups.id = group_participations.group_id' }
    else
      { :conditions => ['groups.deleted_at IS NULL'],
        :joins => 'LEFT JOIN groups ON group_categories.id = groups.group_category_id' }
    end.merge(:select => 'group_categories.*, count(distinct(groups.id)) as count',
              :group => 'groups.group_category_id' )
  }
end
