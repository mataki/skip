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

class GroupParticipation < ActiveRecord::Base
  belongs_to :user
  belongs_to :group, :conditions => 'groups.deleted_at IS NULL'

  named_scope :active, proc {
    { :conditions => { :waiting => false } }
  }

  named_scope :waiting, proc {
    { :conditions => { :waiting => true } }
  }

  named_scope :except_owned, proc {
    { :conditions => { :owned => false } }
  }

  named_scope :only_owned, proc {
    { :conditions => { :owned => true }, :include => [:user] }
  }

  named_scope :order_new, proc {
    { :order => "group_participations.updated_on DESC" }
  }

  N_('GroupParticipation|Waiting|true')
  N_('GroupParticipation|Waiting|false')
  N_('GroupParticipation|Owned|true')
  N_('GroupParticipation|Owned|false')

  def after_save
    group.update_attribute(:updated_on, Time.now) if group && !waiting?
  end

  def after_destroy
    group.update_attribute(:updated_on, Time.now) if group
  end

  # TODO 回帰テストを書く
  def self.joined?(target_user, target_group)
    !!find_by_user_id_and_group_id_and_waiting(target_user, target_group, false)
  end

  # TODO 回帰テストを書く
  def self.owned?(target_user, target_group)
    !!find_by_user_id_and_group_id_and_waiting_and_owned(target_user, target_group, false, true)
  end

  # TODO 回帰テストを書く
  def join! target_user, options = {}
    self.waiting = (!options[:force] && self.group.protected?)
    if self.new_record?
      self.save!
      target_user.notices.create!(:target => self) unless target_user.notices.find_by_target_id(self.group.id)
      if block_given?
        yield true, self
      else
        true
      end
    else
      self.errors.add_to_base _("%s has already joined / applied to join this group.") % target_user.name
      if block_given?
        yield false, self
      else
        false
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    self.errors.add_to_base _('Joined the group failed.')
    if block_given?
      yield false, self
    else
      false
    end
  end

  # TODO 回帰テストを書く
  def leave
    Group.transaction do
      if notice = self.user.notices.find_by_target_id(self.group.id)
        notice.destroy
      end
      self.destroy
      true
    end
  end

  def full_accessible? target_user = self.user
    (target_user == self.user || self.group.owned?(target_user))
  end

  def to_s
    return '[id:' + id.to_s + ', user_id:' + user_id.to_s + ', group_id:' + group_id.to_s + ']'
  end
end
