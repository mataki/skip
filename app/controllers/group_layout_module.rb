module GroupLayoutModule
  def group_tab_menu_source participation
    tab_menu_source = []
    tab_menu_source << {:label => _('Summary'), :options => {:controller => 'group', :action => 'show'}}
    tab_menu_source << {:label => _('Members List'), :options => {:controller => 'group', :action => 'users'}}
    tab_menu_source << {:label => _('BBS'), :options => {:controller => 'group', :action => 'bbs'}}
    tab_menu_source << {:label => _('New Posts'), :options => {:controller => 'group', :action => 'new'}} if participating?(participation)
    tab_menu_source << {:label => _('Shared Files'), :options => {:controller => 'share_file', :action => "list"}}
    tab_menu_source << {:label => _('Admin'), :options => {:controller => 'group', :action => 'manage'}} if participating?(participation) and participation.owned?
    tab_menu_source
  end

  # TODO Group#participating?に順次置き換えていって最終的に削除する。
  def participating? participation
    participation and participation.waiting? != true
  end

end
