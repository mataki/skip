ActionController::Routing::Routes.draw do |map|

  map.root    :controller => 'mypage', :action => 'index'

  map.connect 'images/*path',
              :controller => 'image',
              :action     => 'show'

  map.share_file  ':controller_name/:symbol_id/files/:file_name',
                  :controller => 'share_file',
                  :action => 'download',
                  :requirements => {  :file_name => /.*/ }

  map.connect 'user/:uid/:action',
              :controller => 'user',
              :defaults => { :action => 'show' }

  map.connect 'group/:gid/:action',
              :controller => 'group',
              :defaults => { :action => 'show' }

  map.connect 'bookmark/:action/:uri',
              :controller => 'bookmark',
              :defaults => { :action => 'show' },
              :uri => /.*/

  map.connect 'page/:id',
              :controller => 'board_entries',
              :action => 'forward'

  map.connect 'admin/:action',
              :controller => 'admin',
              :defaults => { :action => 'manage' }

  map.connect 'login', :controller => 'platform', :action => 'login'
  map.connect 'logout', :controller => 'platform', :action => 'logout'
  map.connect 'session/:sso_sid', :controller => 'platform', :action => 'session_info'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.web_parts 'services/:action.js', :controller => 'services'
end
