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

class Antenna < ActiveRecord::Base
  belongs_to :user
  has_many :antenna_items, :dependent => :destroy
  acts_as_list :scope => :user_id

  validates_length_of :name, :minimum=>1, :message =>_('requires 1 or more characters.')
  validates_length_of :name, :maximum=>10, :message =>_('accepts 10 or less characters only.')

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "name" => "Name of Antena",
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  def count
    @count
  end
  def count=(val)
    @count = val
  end

  def antenna_type
    @antenna_type
  end
  def antenna_type=(val)
    @antenna_type = val
  end

  def included
    @included
  end
  def included=(val)
    @included = val
  end

  # アンテナ詳細から検索条件を引っ張ってくる
  def get_search_conditions
    symbols = []
    keyword = ''
    self.antenna_items.each do |item|
      symbols << item.value if item.value_type.intern == :symbol
      keyword << item.value if item.value_type.intern == :keyword
    end
    return symbols, keyword
  end

  def self.find_with_counts user_id, login_user_symbols
    return Antenna.find(:all,
                        :conditions => ["user_id = ?", user_id],
                        :include => [:antenna_items],
                        :order => "position").map do |antenna|
      if antenna.antenna_items.size > 0
        symbols, keyword = antenna.get_search_conditions

        find_params = BoardEntry.make_conditions(login_user_symbols, :symbols => symbols, :keyword => keyword)
        find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
        find_params[:conditions] << false << user_id

        antenna.count = BoardEntry.count(:conditions => find_params[:conditions],
                                         :include => find_params[:include] | [:user_readings])
      end
      antenna.count ||= 0
      antenna
    end
  end

  def self.find_with_included user_id, symbol
    return Antenna.find(:all,
                        :conditions => ["user_id = ?", user_id],
                        :include => [:antenna_items],
                        :order => "position").map do |antenna|
      antenna.antenna_items.each do |item|
        antenna.included = true if item.value_type.intern == :symbol && item.value == symbol
      end
      antenna.included ||= false
      antenna
    end
  end

  def self.get_system_antennas user_id, login_user_symbols, login_user_groups
    antennas = []

    find_params = BoardEntry.make_conditions(login_user_symbols, {:category=>'連絡'})
    find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
    find_params[:conditions] << false << user_id
    antenna_message = Antenna.new(:name => _("Messages for you"), :user_id => user_id)
    antenna_message.antenna_type = "message"
    antenna_message.count = BoardEntry.count(:conditions => find_params[:conditions],
                                             :include => find_params[:include] | [:user_readings])
    antennas << antenna_message

    # コメントの行方
    find_params = BoardEntry.make_conditions(login_user_symbols)
    find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
    find_params[:conditions] << false << user_id
    find_params[:conditions][0] << " and board_entry_comments.user_id = ?"
    find_params[:conditions] << user_id
    antenna_comment = Antenna.new(:name => _("Trace Comments"), :user_id => user_id)
    antenna_comment.antenna_type = "comment"
    antenna_comment.count = BoardEntry.count(:conditions => find_params[:conditions],
                                             :include => find_params[:include] | [:user_readings, :board_entry_comments])
    antennas << antenna_comment

    # ブクマの行方 /page/% をブクマしている人のみに表示する
    if (bookmarks = Bookmark.find(:all,
                                  :conditions => ["bookmark_comments.user_id = ? and url like '/page/%'", user_id],
                                  :include => [:bookmark_comments])).size > 0
      urls = UserReading.find(:all,
                              :select => "board_entry_id",
                              :conditions => ["user_readings.read = ? and user_id = ?", false, user_id])
      urls.map! {|item| '/page/'+item.board_entry_id.to_s }

      antenna_comment = Antenna.new(:name => _("Track of Bookmarks"), :user_id => user_id)
      antenna_comment.antenna_type = "bookmark"
      antenna_comment.count = 0
      bookmarks.each { |bookmark| antenna_comment.count+=1 if urls.include?(bookmark.url) } if urls.size > 0
      antennas << antenna_comment
    end

    if login_user_groups.size > 0
      find_params = BoardEntry.make_conditions login_user_symbols, { :symbols => login_user_groups }
      find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
      find_params[:conditions] << false << user_id
      antenna_group = Antenna.new(:name => _("Your Groups"), :user_id => user_id)
      antenna_group.antenna_type = "group"
      antenna_group.count = BoardEntry.count(:conditions => find_params[:conditions],
                                           :include => find_params[:include] | [:user_readings])
      antennas << antenna_group
    end

    antennas
  end

  def self.create_initial user
    unless SkipEmbedded::InitialSettings['initial_antenna'].blank? or SkipEmbedded::InitialSettings['antenna_default_group'].blank?
      antenna = new(:user_id => user.id, :name => SkipEmbedded::InitialSettings['initial_antenna'], :position => 1)
      SkipEmbedded::InitialSettings['antenna_default_group'].each do |default_gid|
        if Group.active.count(:conditions => ["gid in (?)", default_gid]) > 0
          antenna.antenna_items.build(:value_type => "symbol", :value => "gid:"+default_gid)
        end
      end
      antenna
    end
  end

  def self.create_initial! user
    antenna = create_initial(user)
    antenna.save! if antenna
  end
end
