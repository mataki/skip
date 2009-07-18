module UserLayoutModule
  def user_tab_menu_source user
    tab_menu_source = [
      {:label => _('Profile'), :options => {:controller => 'user', :action => 'show'}},
      {:label => _('Blog'), :options => {:controller => 'user', :action => 'blog'}},
      {:label => _('Shared Files'), :options => {:controller => 'share_file', :action => 'list'}},
      {:label => _('Socials'), :options => {:controller => 'user', :action => 'social'}},
      {:label => _('Groups Joined'), :options => {:controller => 'user', :action => 'group'}},
      {:label => _('Bookmarks'), :options => {:controller => 'bookmark', :action => 'list'}} ]

    if user.id != current_user.id
      if Chain.count(:conditions => ["from_user_id = ? and to_user_id = ?", current_user.id, user.id]) <= 0
        tab_menu_source << {:label => _('Create introductions'), :options => {:controller => 'user', :action => 'new_chain'}}
      else
        tab_menu_source << {:label => _('Edit introductions'), :options => {:controller => 'user', :action => 'edit_chain'}}
      end
    else
      tab_menu_source.unshift({:label => _('Home'), :options => {:controller => 'mypage', :action => 'index'}, :selected_actions => %w(index entries entries_by_date entries_by_antenna)})
      tab_menu_source << {:label => _('Footprints'), :options => {:controller => 'mypage', :action => 'trace'}}
      tab_menu_source << {:label => _('Admin'), :options => {:controller => 'mypage', :action => 'manage'}}
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
    if @user = User.find_by_uid(params[:uid])
      @user.mark_track current_user.id if @user.id != current_user.id
    else
      flash[:warn] = _('User does not exist.')
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end
end
