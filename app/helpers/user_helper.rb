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

module UserHelper
  include BoardEntriesHelper

  # メニューの生成
  def get_social_menu_items selected_menu
    @@menus = [{:name => _("Introduction from other users"),     :menu => "social_chain" },
               {:name => _("Introduction for other users"),   :menu => "social_chain_against" }]
    get_menu_items @@menus, selected_menu, "social"
  end

  def social_tag_cloud user, tags = nil
    output = ""
    tags ||= ChainTag.tags_used_to(user).all(:select => '*, count(tags.id) as count')
    tag_cloud tags do |name, count, css_class|
      output << link_to(name, users_path(:tag_words => name), :class => css_class)
      output << "<span style='color: silver; font-size: 10px;'>(#{count})</span> "
    end
    output
  end

  def profile_show_tag input_type_processer, user_profile_value
    if input_type_processer.class == UserProfileMaster::RichTextProcesser
      value_str = user_profile_value ? user_profile_value.value : ""
      symbol = user_profile_value ? user_profile_value.user.symbol : nil
      content_tag(:div, render_richtext(value_str, symbol), :class => "input_value rich_value")
    else
      value_str = user_profile_value ? user_profile_value.value : ""
      content_tag(:div, h(value_str), :class => "input_value") + content_tag(:div, nil, :class => "input_bottom")
    end
  end

  def user_tab_menu_source user
    # TODO mypage#setup_layoutのtab_menu_source構築と重複が多い。DRYにしたい。
    tab_menu_source = [ {:label => _('Profile'), :options => {:controller => 'user', :action => 'show', :uid => user.uid}} ]

    tab_menu_source << {:label => _('Blog'), :options => {:controller => 'user', :action => 'blog', :uid => user.uid, :archive => 'all', :sort_type => 'date', :type => 'entry'}} unless BoardEntry.owned(user).accessible(current_user).empty?
    tab_menu_source << {:label => _('Shared Files'), :options => {:controller => 'share_file', :action => 'list', :uid => user.uid}} unless ShareFile.owned(user).accessible(current_user).empty?
    tab_menu_source << {:label => _('Socials'), :options => {:controller => 'user', :action => 'social', :uid => user.uid}} unless user.against_chains.empty?
    tab_menu_source << {:label => _('Groups Joined'), :options => {:controller => 'user', :action => 'group', :uid => user.uid}} unless user.groups.participating(user).empty?
    tab_menu_source << {:label => _('Bookmarks'), :options => {:controller => 'bookmark', :action => 'list', :uid => user.uid}} unless user.bookmark_comments.empty?

    if user.id == current_user.id
      tab_menu_source.unshift({:label => _('Home'), :options => {:controller => 'mypage', :action => 'index'}, :selected_actions => %w(index entries entries_by_date entries_by_antenna)})
    end
    tab_menu_source
  end

  def user_main_menu user
    user.id == current_user.id ? _('My Page') : _('Users')
  end

  def user_title user
    user.id == current_user.id ? _('My Page') : _("Mr./Ms. %s") % user.name
  end

  def user_menu_option user
    { :uid => user.uid }
  end

  def load_user
    if @user = current_target_user
      @user.mark_track current_user.id if @user.id != current_user.id
    else
      flash[:warn] = _('User does not exist.')
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end
end
