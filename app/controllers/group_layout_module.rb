module GroupLayoutModule
  def group_tab_menu_source group
    tab_menu_source = []
    tab_menu_source << {:label => _('Summary'), :options => {:controller => 'group', :action => 'show'}}
    tab_menu_source << {:label => _('Members List'), :options => {:controller => 'group', :action => 'users'}}
    tab_menu_source << {:label => _('BBS'), :options => {:controller => 'group', :action => 'bbs', :sort_type => 'date'}}
    tab_menu_source << {:label => _('Shared Files'), :options => {:controller => 'share_file', :action => "list"}} unless ShareFile.owned(group).accessible(current_user).empty?
    tab_menu_source << {:label => _('Admin'), :options => {:controller => 'group', :action => 'manage'}} if group.administrator?(current_user)
    tab_menu_source
  end
end
