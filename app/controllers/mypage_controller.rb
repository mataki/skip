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

require 'jcode'
require 'open-uri'
require "resolv-replace"
require 'timeout'
require 'rss'
class MypageController < ApplicationController
  before_filter :setup_layout
  helper :calendar

  verify :method => :post, :only => [ :destroy_portrait, :save_portrait, :update_profile,
                                      :update_customize, :update_message_unsubscribes, :apply_password,
                                      :apply_ident_url, :add_antenna, :delete_antenna, :delete_antenna_item, :move_antenna_item,
                                      :change_read_state, :apply_email, :update_email, :set_antenna_name, :sort_antenna],
         :redirect_to => { :action => :index }

  # マイページ（ホーム）の表示
  def index
    # マイページの左側部分
    @year = params[:year] ? params[:year].to_i : Time.now.year
    @month = params[:month] ? params[:month].to_i : Time.now.month
    @day = params[:day] ? params[:day].to_i : Time.now.day
    unless Date.valid_date?(@year, @month, @day)
      @year, @month, @day = Time.now.year, Time.now.month, Time.now.day
    end

    @entry_count = get_entry_count(@year, @month)

    @user = current_user

    @my_info = {
      :access_count => @user.user_access.access_count,
      :subscriber_count => AntennaItem.count(:conditions => ["antenna_items.value = ?", @user.symbol],
                                             :select => "distinct user_id",
                                             :joins => "left outer join antennas on antenna_id = antennas.id"),
      :blog_count => BoardEntry.count(:conditions => ["user_id = ? and entry_type = ?", @user.id, "DIARY"]),
      :using_day => ((Time.now - @user.created_on) / (60*60*24)).to_i + 1
    }

    # マイページの右側部分（パラメタに応じて内容を変更）
    if params[:year] && params[:month] && params[:day]
      @partial, @locals = get_index_day(@year, @month, @day)

    elsif antenna_type = params[:antenna_type]
      @partial, @locals = get_index_antenna_system(antenna_type)

    elsif antenna_id = params[:antenna_id]
      @partial, @locals = get_index_antenna(antenna_id)

    elsif list_type = params[:list_type]
      @partial, @locals = get_index_list(list_type, params[:all])

    else
      @partial, @locals = get_index_default
    end
  end

  def load_calendar
    render :partial => "shared/calendar",
           :locals => { :sel_year => params[:year].to_i,
                        :sel_month => params[:month].to_i,
                        :sel_day => nil,
                        :item_count => get_entry_count(params[:year], params[:month])}
  end

  def ado_antennas
    render :partial => "antennas", :object =>  find_antennas, :locals => {:system_antennas => find_system_antennas }
  end

  # 汎用的なajax対応アクション
  # param[:target]で指定した内容をページ単位表示する
  def load_entries
    partial_name = params[:page_name] ||= "page_space"
    render :partial => partial_name, :locals => self.send('find_' +  params[:target] + '_as_locals')
  end

  def load_rss_feed
    feeds = []
    Admin::Setting.mypage_feed_settings.each do |setting|
      feed = nil
      timeout(Admin::Setting.mypage_feed_timeout.to_i) do
        feed = open(setting[:url], :proxy => INITIAL_SETTINGS['proxy_url']){ |f| RSS::Parser.parse(f.read) }
      end
      feed.channel.title = setting[:title] if setting[:title]
      limit = (setting[:limit]||Admin::Setting.mypage_feed_default_limit)
      feed.items.slice!(limit..-1) if feed.items.size > limit
      feeds << feed
    end
    render :partial => "rss_feed", :locals => { :feeds => feeds }
  rescue TimeoutError
    render :text => "RSSの読み込みがタイムアウトしました。"
    return false
  rescue Exception => e
    logger.error e
    e.backtrace.each { |line| logger.error line}
    render :text => "RSSの読み込みに失敗しました。"
    return false
  end

  # tab_menu
  def profile
    flash.keep(:notice)
    redirect_to get_url_hash('show')
  end

  # tab_menu
  def blog
    redirect_to get_url_hash('blog')
  end

  # tab_menu
  def social
    redirect_to get_url_hash('social')
  end

  # tab_menu
  def bookmark
    redirect_to get_url_hash('bookmark')
  end

  # tab_menu
  def group
    redirect_to get_url_hash('group')
  end

  # tab_menu
  def share_file
    redirect_to get_url_hash('share_file')
  end

  # tab_menu
  def trace
    @access_count = current_user.user_access.access_count
    @access_tracks = current_user.tracks
  end

  # tab_menu
  def manage
    @title = "自分の管理"
    @user = current_user
    @menu = params[:menu] || "manage_profile"
    case @menu
    when "manage_profile"
      @profile = @user.profile || UserProfile.new
    when "manage_password"
      redirect_to_with_deny_auth(:action => :manage) and return unless login_mode?(:password)
      @user = User.new
    when "manage_email"
      @applied_email = AppliedEmail.find_by_user_id(session[:user_id]) || AppliedEmail.new
    when "manage_openid"
      redirect_to_with_deny_auth(:action => :manage) and return unless login_mode?(:free_rp)
      @openid_identifier = @user.openid_identifiers.first || OpenidIdentifier.new
    when "manage_portrait"
      @picture = Picture.find_by_user_id(@user.id) || Picture.new
    when "manage_customize"
      custom = UserCustom.find_by_user_id(@user.id)
      @user_custom = custom || UserCustom.new
    when "manage_antenna"
      @antennas = find_antennas
    when "manage_message"
      @unsubscribes = UserMessageUnsubscribe.get_unscribe_array(session[:user_id])
    when "record_mail"
      set_data_for_record_mail
    when "record_post"
      set_data_for_record_blog
    end
    render :partial => @menu, :layout => "layout"
  end

  # post_action
  def destroy_portrait
    if picture = Picture.find_by_user_id(session[:user_id])
      picture.destroy
      flash[:notice] = "画像を削除しました"
    end
    redirect_to :action => 'manage', :menu => 'manage_portrait'
  end

  # post_action
  def save_portrait
    begin
      unless params[:picture][:picture].is_a? ActionController::UploadedFile
        raise ActiveRecord::RecordInvalid::new("ファイル形式が不正です。")
      end
      Picture.transaction do
        if picture = Picture.find_by_user_id(session[:user_id])
          picture.destroy
        end
        picture = Picture.new(params[:picture])
        picture.user_id = session[:user_id]
        picture.save!
        flash[:notice] = "画像を変更しました"
      end
    rescue ActiveRecord::RecordInvalid => e
      flash[:warning] = e.message
    end
    redirect_to :action => 'manage', :menu => 'manage_portrait'
  end

  # post_action
  def update_profile
    @user = current_user
    @user.attributes = params[:user]

    @profile = @user.user_profile
    @profile.attributes_for_registration(params)

    User.transaction do
      @profile.save!
      @user.save!

      flash[:notice] = 'ユーザ情報の更新に成功しました。'
      redirect_to :action => 'profile'
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    @error_msg = []
    @error_msg.concat @user.errors.full_messages.reject{|msg| msg.include?("User profile") } unless @user.valid?
    @error_msg.concat @profile.errors.full_messages if @profile and @profile.errors
    render :partial => 'manage_profile', :layout => "layout"
  end

  # post_action
  # メール通知設定
  # 画面表示とテーブルレコードが逆なので注意
  # Message::MESSAGE_TYPESにあるけど、params["message_type"]にないときにcreate
  def update_message_unsubscribes
    UserMessageUnsubscribe.delete_all(["user_id = ?", session[:user_id]])
    Message::MESSAGE_TYPES.keys.each do |message_type|
      unless  params["message_type"] && params["message_type"][message_type]
        UserMessageUnsubscribe.create(:user_id => session[:user_id], :message_type => message_type )
      end
    end
    flash[:notice] = 'お知らせメールの通知設定を更新しました。'
    redirect_to :action => 'manage', :menu => 'manage_message'
  end

  def apply_password
    redirect_to_with_deny_auth(:action => :manage) and return unless login_mode?(:password)

    @user = current_user
    @user.change_password(params[:user])
    if @user.errors.empty?
      flash[:notice] = 'パスワードを変更しました。'
      redirect_to :action => :manage, :menu => :manage_password
    else
      @menu = 'manage_password'
      render :partial => 'manage_password', :layout => 'layout'
    end
  end

  def apply_email
    if @applied_email = AppliedEmail.find_by_user_id(session[:user_id])
      @applied_email.email = params[:applied_email][:email]
    else
      @applied_email = AppliedEmail.new(params[:applied_email])
      @applied_email.user_id = session[:user_id]
    end

    if @applied_email.save
      UserMailer.deliver_sent_apply_email_confirm(@applied_email.email, "#{root_url}mypage/update_email/#{@applied_email.onetime_code}/")
      flash.now[:notice] = "メールアドレス変更の申請を受け付けました。メールをご確認ください。"
    else
      flash.now[:warning] = "処理に失敗しました。もう一度申請してください。"
    end
    @menu = 'manage_email'
    @user = current_user
    render :partial => 'manage_email', :layout => "layout"
  end

  def update_email
    onetime_code = params[:id]
    if @applied_email = AppliedEmail.find_by_user_id_and_onetime_code(session[:user_id], onetime_code)
      @user = current_user
      old_email = @user.user_profile.email
      @user.user_profile.email = @applied_email.email
      if @user.save
        @applied_email.destroy
        flash[:notice] = "メールアドレスが正しく更新されました。"
        redirect_to :action => 'profile'
      else
        @user.user_profile.email = old_email
        @menu = 'manage_email'
        flash[:notice] = "既に登録されているメールアドレスです。メールアドレスの変更をやり直してください。"
        render :partial => 'manage_email', :layout => "layout"
      end
    else
      flash[:notice] = '指定されたページは存在しません。'
      redirect_to :action => 'index'
    end
  end

  def apply_ident_url
    redirect_to_with_deny_auth(:action => :manage) and return unless login_mode?(:free_rp)
    @openid_identifier = if current_user.openid_identifiers.empty?
                           current_user.openid_identifiers.build
                         else
                           current_user.openid_identifiers.first
                         end
    @openid_identifier.url = params[:openid_identifier][:url] if params[:openid_identifier]

    if @openid_identifier.save
      flash[:notice] = _('OpenID URLを設定しました。')
      redirect_to :action => :manage, :menu => :manage_openid
    else
      render :partial => 'manage_openid', :layout => 'layout'
    end
  end

  # post_action
  def update_customize
    result = false
    if @user_custom = UserCustom.find_by_user_id(session[:user_id])
      result = @user_custom.update_attributes(params[:user_custom])
    else
      @user_custom = UserCustom.new(params[:user_custom])
      @user_custom.user_id = session[:user_id]
      result = @user_custom.save
    end

    if result
      flash[:notice] = '正しく更新されました。'
      session[:user_custom_theme] = @user_custom.theme
      redirect_to :action => 'manage', :menu => 'manage_customize'
    else
      render :partial => 'manage_customize', :layout => "layout"
    end
  end

  # ajax
  def ado_my_groups
    conditions = ["group_participations.user_id = ? and group_participations.favorite = true", session[:user_id]]
    groups = Group.find(:all,
                        :conditions => conditions,
                        :order => "group_participations.created_on DESC",
                        :include => :group_participations)
    symbol2name_hash = {}
    groups.each do |group|
      symbol2name_hash[group.gid] = group.name
    end
    render :text => symbol2name_hash.to_json
  end

  # ajaxで、未読・既読を変更する
  def change_read_state
    UserReading.create_or_update(session[:user_id], params[:board_entry_id], params[:read])
    render :text => ""
  end

  def get_antennas
    render :partial => 'antennas', :object => find_antennas, :locals => { :system_antennas => find_system_antennas }
  end

  def set_antenna_name
    id = params[:element_id] ? params[:element_id].split('_')[3] : nil

    antenna = Antenna.find(id)
    unless antenna.user_id == session[:user_id]
      render :text => ""
      return false
    end
    antenna.name = params[:value]
    if antenna.save
      # Inplaceエディタ内で直接ここで返した文字列を表示するためにHTMLエスケープする
      render :text => ERB::Util.html_escape(antenna.name)
    else
      render :text => antenna.errors.full_messages.first, :status => 500
    end
  end

  def add_antenna
    Antenna.create(:user_id => session[:user_id], :name => params[:name])
    render :partial => 'antennas', :object => find_antennas, :locals => { :for_manage => true }
  end

  def delete_antenna
    antenna = Antenna.find(params[:antenna_id])
    unless antenna.user_id == session[:user_id]
      render :text => ""
      return false
    end
    antenna.destroy
    render :partial => 'antennas', :object => find_antennas, :locals => { :for_manage => true }
  end

  def delete_antenna_item
    item = AntennaItem.find(params[:antenna_item_id])
    unless item.antenna.user_id == session[:user_id]
      render :text => ""
      return false
    end
    item.destroy
    render :partial => 'antennas', :object => find_antennas, :locals => { :for_manage => true }
  end

  def move_antenna_item
    AntennaItem.update(params[:antenna_item_id], :antenna_id => params[:antenna_id])
    render :partial => 'antennas', :object => find_antennas, :locals => { :for_manage => true }
  end

  def sort_antenna
    antennas = Antenna.find(:all,
                            :conditions => ["user_id = ?", session[:user_id]],
                            :order => "position")
    target_pos = Integer(params[:target_pos])

    antennas.each_with_index do |antenna, index|
      if antenna.id.to_s == params[:source_antenna_id]
        if target_pos > antenna.position
          antennas.insert(target_pos, antenna)
          antennas.delete_at(index)
        else
          antennas.delete_at(index)
          antennas.insert(target_pos-1, antenna)
        end
        break
      end
    end
    antennas.each_with_index do |antenna, index|
      if antenna && (antenna.position != (index + 1))
        antenna.position = index + 1;
        antenna.save
      end
    end

    render :partial => 'antennas', :object => find_antennas, :locals => { :for_manage => true }
  end

  def antenna_list
    render :text => current_user_antennas_as_json
  end
private
  def setup_layout
    @main_menu = @title = 'マイページ'

    @tab_menu_source = [ ['ホーム', 'index'],
                         ['プロフィール', 'profile'],
                         ['ブログ', 'blog'],
                         ['ファイル','share_file'],
                         ['ソーシャル', 'social'],
                         ['ブックマーク', 'bookmark'],
                         ['参加グループ', 'group'],
                         ['足跡', 'trace'],
                         ['管理', 'manage'] ]
  end

  def set_data_for_record_mail
    @pages, @mails = paginate(:mail,
                              :per_page =>20,
                              :select => "*, mails.updated_on as mail_updated_on",
                              :conditions => ["mails.from_user_id = ?", session[:uid]],
                              :order_by => "mails.id DESC")

    #タイトルのリンクができるかできないかを判定する材料を取得する(ヘルパーで使う)
    user_entry_no_list = @mails.map{ |mail| mail.user_entry_no }
    if user_entry_no_list.size > 0
      board_entries = BoardEntry.find(:all, :conditions =>["user_id = ? and user_entry_no in (?)",  session[:user_id], user_entry_no_list])
      @board_enries_by_user_entry_no = Hash.new
      board_entries.each{ |board_entry| @board_enries_by_user_entry_no.store(board_entry.user_entry_no, board_entry) }
    end

    #送信先のリンクができるかできないかを判定する材料を取得する(ヘルパーで使う)
    uid_list = gid_list = []
    for mail in @mails
      id = mail.symbol_id
      case mail.symbol_type
      when 'uid'
        uid_list << id
      when 'gid'
        gid_list << id
      end
    end

    @exist_item_by_symbol = Hash.new
    if uid_list.size > 0
      users = User.find(:all, :conditions =>['user_uids.uid in (?)', uid_list], :include => [:user_uids])
      users.each{ |user|  @exist_item_by_symbol.store(user.symbol, user) }
    end
    if gid_list.size > 0
      groups = Group.find(:all, :conditions =>['gid in (?)', gid_list])
      groups.each{ |group|  @exist_item_by_symbol.store(group.symbol, group) }
    end
  end

  def set_data_for_record_blog
    login_user_id = session[:user_id]

    options = {}
    options[:writer_id] = login_user_id
    options[:keyword] = params[:keyword]
    options[:category] = params[:category]
    find_params = BoardEntry.make_conditions(login_user_symbols, options)

    @pages, @board_entries = paginate(:board_entry,
                                      :per_page => 20,
                                      :order => "last_updated DESC,board_entries.id DESC",
                                      :conditions => find_params[:conditions],
                                      :include => find_params[:include])

    @symbol2name_hash = BoardEntry.get_symbol2name_hash @board_entries

    find_params = BoardEntry.make_conditions(login_user_symbols, {:writer_id => login_user_id})
    @categories = BoardEntry.get_category_words(find_params)
  end

  def get_url_hash action
    login_user_symbol_type, login_user_symbol_id = Symbol.split_symbol(session[:user_symbol])
    { :controller => 'user', :action => action, :uid => login_user_symbol_id }
  end

  def find_antennas
    Antenna.find_with_counts session[:user_id], login_user_symbols
  end

  def find_system_antennas
    Antenna.get_system_antennas session[:user_id], login_user_symbols, login_user_groups
  end

  # 月の中で記事が含まれている日付と記事数のハッシュと、
  # 引数は、指定の年と月
  def get_entry_count year, month
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY'})
    find_params[:conditions][0] << " and YEAR(date) = ? and MONTH(date) = ?"
    find_params[:conditions] << year << month

    entry_count = {}
    entry_days = BoardEntry.find(:all,
                                 :select => "DAY(date) as date_, count(board_entries.id) as count",
                                 :order => "date_ ASC",
                                 :group => "date_",
                                 :conditions=> find_params[:conditions],
                                 :joins => "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id")
    entry_days.each do |item|
      entry_count[item.date_.to_i] = item.count
    end
    return entry_count
  end

  # マイページで日付ごとに記事を表示するためのデータを取得する
  # 引数は指定の日付
  def get_index_day(year, month, day)
    partial = "index_day"
    locals = {
      :selected_day => Date.new(year, month, day),
      :next_day => nil,
      :prev_day => nil
    }

    # その日の一覧
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY'})
    find_params[:conditions][0] << " and DATE(date) = ?"
    find_params[:conditions] << locals[:selected_day]
    locals[:entries] = BoardEntry.find(:all,
                                       :conditions=> find_params[:conditions],
                                       :order=>"date ASC",
                                       :include => find_params[:include] | [ :user, :state ])

    # 記事のある次の日
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY'})
    find_params[:conditions][0] << " and DATE(date) > ?"
    find_params[:conditions] << locals[:selected_day]
    next_day = BoardEntry.find(:first,
                               :select => "date, DATE(date) as count_date, count(board_entries.id) as count",
                               :conditions=> find_params[:conditions],
                               :group => "count_date",
                               :order => "date ASC",
                               :limit => 1,
                               :joins => "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id")

    # 記事のある前の日
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY'})
    find_params[:conditions][0] << " and DATE(date) < ?"
    find_params[:conditions] << locals[:selected_day]
    prev_day = BoardEntry.find(:first,
                               :select => "date, DATE(date) as count_date, count(board_entries.id) as count",
                               :conditions=> find_params[:conditions],
                               :group => "count_date",
                               :order => "date DESC",
                               :limit => 1,
                               :joins => "LEFT OUTER JOIN entry_publications ON entry_publications.board_entry_id = board_entries.id")

    locals[:next_day] = next_day.date if next_day
    locals[:prev_day] = prev_day.date if prev_day

    return partial, locals
  end

  # マイページでシステムアンテナの記事を表示するためのデータを取得する
  # 引数は、システムアンテナのタイプ
  def get_index_antenna_system(antenna_type)
    partial = "index_antenna"
    locals = {
      :type_symbol => :antenna_type, :type_value => antenna_type,
      :entries => [], :entries_pages => nil, :user_unreadings => {}
    }

    find_params = []
    case antenna_type
    when "message"
      locals[:title_name] = "あなたへ宛てた連絡"
      find_params = BoardEntry.make_conditions login_user_symbols, { :category=>'連絡' }
    when "comment"
      locals[:title_name] = "過去にあなたがコメントを残した記事"
      find_params = BoardEntry.make_conditions(login_user_symbols)
      find_params[:conditions][0] << " and board_entry_comments.user_id = ?"
      find_params[:conditions] << session[:user_id]
      find_params[:include] << :board_entry_comments
    when "bookmark"
      bookmarks = Bookmark.find(:all,
                                :conditions => ["bookmark_comments.user_id = ? and bookmarks.url like '/page/%'", session[:user_id]],
                                :include => [:bookmark_comments])
      ids = []
      bookmarks.each do |bookmark|
        ids << bookmark.url.gsub(/\/page\//, "")
      end

      locals[:title_name] = "あなたがブックマークした記事"
      find_params = BoardEntry.make_conditions(login_user_symbols)
      find_params[:conditions][0] << " and board_entries.id in (?)"
      find_params[:conditions] << ids
    when "group"
      return if login_user_groups.size <= 0
      locals[:title_name] = "参加中のグループの掲示板の書き込み"
      find_params = BoardEntry.make_conditions login_user_symbols, { :symbols => login_user_groups }
    end

    unless params[:read]
      find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
      find_params[:conditions] << false << session[:user_id]
      find_params[:include] << :user_readings
    end
    locals[:entries_pages], locals[:entries] = paginate(:board_entry,
                                                        :per_page => 20,
                                                        :order=>"last_updated DESC,board_entries.id DESC",
                                                        :conditions=> find_params[:conditions],
                                                        :include => find_params[:include] | [ :user, :state ])

    if locals[:entries].size > 0
      user_readings_conditions = ["user_id = ? and board_entry_id in (?)"]
      user_readings_conditions << session[:user_id] << locals[:entries].map {|entry| entry.id }
      user_readings = UserReading.find(:all, :conditions => user_readings_conditions)
      user_readings.each do |user_reading|
        locals[:user_unreadings][user_reading.board_entry_id] = user_reading unless user_reading.read
      end

      locals[:symbol2name_hash] = BoardEntry.get_symbol2name_hash locals[:entries]
    end
    return partial, locals
  end

  # マイページでアンテナの記事を表示するためのデータを取得する
  # 引数は、アンテナのID
  def get_index_antenna(antenna_id)
    partial = "index_antenna"
    locals = {
      :type_symbol => :antenna_id, :type_value => antenna_id,
      :entries => [], :entries_pages => nil, :user_unreadings => {}
    }

    antenna = Antenna.find(antenna_id)
    locals[:title_name] = antenna.name
    locals[:antenna_items] = antenna.antenna_items
    if antenna.antenna_items.size > 0
      symbols, keyword = antenna.get_search_conditions

      find_params = BoardEntry.make_conditions(login_user_symbols, :symbols => symbols, :keyword => keyword)
      unless params[:read]
        find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
        find_params[:conditions] << false << session[:user_id]
        find_params[:include] << :user_readings
      end
      locals[:entries_pages], locals[:entries] = paginate(:board_entry,
                                                          :per_page => 20,
                                                          :order_by => "last_updated DESC,board_entries.id DESC",
                                                          :conditions=> find_params[:conditions],
                                                          :include => find_params[:include] | [ :user, :state ])
      if locals[:entries].size > 0
        user_readings_conditions = ["user_id = ? and board_entry_id in (?)"]
        user_readings_conditions << session[:user_id] <<  locals[:entries].map {|entry| entry.id }
        user_readings = UserReading.find(:all, :conditions => user_readings_conditions)
        user_readings.each do |user_reading|
          locals[:user_unreadings][user_reading.board_entry_id] = user_reading unless user_reading.read
        end
      end
    end
    return partial, locals
  end

  def get_index_list(list_type, show_all = false)
    partial = "index_list"
    options = {:per_page => 20}
    options[:recent_day] = 10 unless show_all

    # partialへのlocal変数で渡すから"_as_locals"
    return partial, self.send('find_' +  list_type + '_as_locals', options)
  end

  def get_index_default
    partial = "index_default"
    recent_day = Admin::Setting.recent_date

    # お知らせ-承認待ちの一覧
    @waiting_groups = Group.find_waitings session[:user_id]

    # あなたへの重要な連絡
    find_params = BoardEntry.make_conditions(login_user_symbols, {:recent_day => recent_day, :categories => ['連絡', '重要']})
    @important_your_messages = BoardEntry.find(:all,
                                               :conditions=> find_params[:conditions],
                                               :order=>"last_updated DESC,board_entries.id DESC",
                                               :include => find_params[:include] | [ :user, :state ])
    symbol2name_hash = BoardEntry.get_symbol2name_hash @important_your_messages

    # システムからの連絡
    system_messages = []
    self_introduction = @user.user_profile.self_introduction
    if self_introduction.blank? || self_introduction.size < 10 || !UserProfile.find_by_user_id(@user.id)
      system_messages << {
        :text => "プロフィールを充実させましょう！",
        :icon => "vcard",
        :option => {:controller => "mypage", :action => "manage"}
      }
    end
    if @user.pictures.size < 1
      system_messages << {
        :text => "プロフィール画像を変更しましょう！",
        :icon => "picture",
        :option => {:controller => "mypage", :action => "manage", :menu => "manage_portrait"}
      }
    end

    system_messages

    # あなたへの連絡
    find_params = BoardEntry.make_conditions(login_user_symbols, {:recent_day => recent_day})
    find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ? and entry_tags.tag_id = ?" #[連絡]タグのTagsテーブルのIDが4
    find_params[:conditions] << false << session[:user_id] << Tag.get_system_tag(Tag::NOTICE_TAG).id
    find_params[:include] << :user_readings
    @mail_your_messages = BoardEntry.find(:all,
                                          :conditions=> find_params[:conditions] ,
                                          :order=>"last_updated DESC,board_entries.id DESC",
                                          :limit=>5,
                                          :include => find_params[:include] | [ :user, :state, :entry_tags ])
    # みんなからの質問！
    questions = find_questions_as_locals(:recent_day => recent_day)
    # 最近の人気記事
    access_blogs = find_access_blogs_as_locals(:recent_day => recent_day)
    # 最新のブログの記事
    recent_blogs = find_recent_blogs_as_locals(:recent_day => recent_day)
    # 最新の掲示板の記事(全体公開のみ)
    recent_bbs = []
    gid_by_category = Group.gid_by_category
    GroupCategory.all.each do |category| # 表示順序の制御
      options = { :group_symbols => gid_by_category[category.id], :recent_day => recent_day, :per_page => 3 }
      recent_bbs << self.send("find_recent_bbs_#{category.code.downcase}_as_locals", options)
    end

    #最近のブックマーク
    @bookmarks = Bookmark.find_visible(5, recent_day)

    # 最近登録されたグループ
    @recent_groups =  Group.find(:all, :order=>"created_on DESC", :conditions=>["created_on > ?" ,Date.today-recent_day], :limit => 10)

    # 最近登録されたユーザ
    @recent_users = User.find(:all, :order=>"created_on DESC", :conditions=>["created_on > ?" ,Date.today-recent_day], :limit => 10)

    locals = {
      :symbol2name_hash => symbol2name_hash,
      :new_comment_entries => @new_comment_entries,
      :waiting_groups => @waiting_groups,
      :important_your_messages => @important_your_messages,
      :system_messages => system_messages,
      :mail_your_messages => @mail_your_messages,
      :questions => questions,
      :access_blogs => access_blogs,
      :recent_blogs => recent_blogs,
      :bookmarks => @bookmarks,
      :recent_users => @recent_users,
      :recent_groups => @recent_groups,
      :recent_bbs => recent_bbs,
      :message_array => Message.get_message_array_by_user_id(session[:user_id])
    }
    return partial, locals
  end

  # 最近の記事一覧を取得する（partial用のオプションを返す）
  # 引数：recent_day = 最近を示す日数（デフォルト10日）
  # 引数：per_page   = １ページの表示数（デフォルト5件）
  def find_recent_blogs_as_locals options = {}
    options = { :recent_day => 10, :per_page => 4 }.merge(options)
    find_params = BoardEntry.make_conditions(login_user_symbols, {:entry_type=>'DIARY', :recent_day=>options[:recent_day], :publication_type => 'public'})
    find_params[:conditions][0] << " and board_entries.title <> 'ユーザー登録しました！'"
    pages_obj, pages = paginate(:board_entry,
                                :per_page =>options[:per_page],
                                :order=>"last_updated DESC,board_entries.id DESC",
                                :conditions=> find_params[:conditions],
                                :include => find_params[:include] | [ :user, :state ])
    locals = {
      :id_name => 'recent_blogs',
      :title_name => '最近投稿された記事',
      :pages => pages,
      :pages_obj => pages_obj,
      :title_icon => "page_copy"
    }
  end

  # 最近のBBS記事一覧を取得するメソッドを動的に生成(partial用のオプションを返す)
  # sendで呼び出すためにカテゴリごとにメソッドを生成
  #
  # 引数：group_symbols    = 検索対象のグループシンボル(デフォルトnil)
  # 引数：recent_day       = 最近を示す日数（デフォルト10日）
  # 引数：per_page         = １ページの表示数（デフォルト3件）
  GroupCategory.all.each do |category|
    define_method( "find_recent_bbs_#{category.code.downcase}_as_locals" ) do |options|
      options ||= {}
      options[:recent_day] ||= 10
      options[:per_page] ||= 3
      recent_bbs_proc category, options
    end
  end

  # 最新のBBS記事一覧partial用オプション生成メソッド
  def recent_bbs_proc category, options
    title   = "最新の掲示板の記事（#{category.name}）"
    id_name = "recent_bbs_#{category.code.downcase}"
    pages_obj, pages = nil, []

    find_options = {:exclude_entry_type=>'DIARY', :publication_type => 'public', :recent_day=>options[:recent_day]}
    find_options[:symbols] = options[:group_symbols] || Group.gid_by_category[category.id]
    if find_options[:symbols].size > 0
      find_params = BoardEntry.make_conditions(login_user_symbols, find_options)
      pages_obj, pages = paginate(:board_entry,
                                  :per_page => options[:per_page],
                                  :order=>"last_updated DESC, board_entries.id DESC",
                                  :conditions=> find_params[:conditions],
                                  :include => find_params[:include] | [ :user, :state ])
    end

    locals = {
      :id_name => id_name,
      :title_name => title,
      :pages => pages,
      :pages_obj => pages_obj,
      :symbol2name_hash => BoardEntry.get_symbol2name_hash(pages)
    }
  end


  # 最近の人気記事一覧を取得する（partial用のオプションを返す）
  # 引数：recent_day = 最近を示す日数（デフォルト10日）
  # 引数：per_page   = １ページの表示数（デフォルト10件）
  def find_access_blogs_as_locals options = {}
    options = { :recent_day => 10, :per_page => 10 }.merge(options)
    find_params = BoardEntry.make_conditions(login_user_symbols, {:publication_type => 'public'})
    find_params[:conditions][0] << " and board_entries.category not like ?"
    find_params[:conditions] << '%[質問]%'
    if options[:recent_day]
      find_params[:conditions][0] << " and last_updated > ?"
      find_params[:conditions] << Date.today-options[:recent_day]
    end
    pages_obj, pages = paginate(:board_entry,
                                :per_page =>options[:per_page],
                                :order=>"board_entry_points.today_access_count DESC, board_entry_points.access_count DESC, board_entries.last_updated DESC, board_entries.id DESC",
                                :conditions=> find_params[:conditions],
                                :include => find_params[:include] | [ :user, :state ])
    locals = {
      :id_name => 'access_blogs',
      :title_name => '最近の人気記事（質問除く）',
      :pages => pages,
      :pages_obj => pages_obj,
      :symbol2name_hash => BoardEntry.get_symbol2name_hash(pages),
      :title_icon => "star"
    }
  end

  # 質問記事一覧を取得する（partial用のオプションを返す）
  # 引数：recent_day = 最近を示す日数（デフォルト10日）
  # 引数：per_page   = １ページの表示数（デフォルト5件）
  def find_questions_as_locals options = {}
    options = { :recent_day => 10, :per_page => 5 }.merge(options)
    find_params = BoardEntry.make_conditions(login_user_symbols, {:recent_day=>options[:recent_day], :category=>'質問'})
    pages_obj, pages = paginate(:board_entry,
                                :per_page =>options[:per_page],
                                :order =>"last_updated DESC,board_entries.id DESC",
                                :conditions=> find_params[:conditions],
                                :include => find_params[:include] | [ :user, :state ])
    locals = {
      :id_name => 'questions',
      :title_name => 'みんなからの質問！',
      :pages => pages,
      :pages_obj => pages_obj,
      :title_icon => "user_comment",
      :delete_categories => '[質問]'
    }
  end

  # 未読記事一覧を取得する（partial用のオプションを返す）
  # 引数：recent_day = 最近を示す日数（デフォルト10日）
  # 引数：per_page   = １ページの表示数（デフォルト5件）
  def find_not_reading_blogs_as_locals options = {}
    options = { :recent_day => 10, :per_page => 5 }.merge(options)
    find_params = BoardEntry.make_conditions(login_user_symbols, {:recent_day=>options[:recent_day]})
    find_params[:conditions][0] << " and user_readings.read = ? and user_readings.user_id = ?"
    find_params[:conditions] << false << session[:user_id]
    find_params[:include] << :user_readings
    pages_obj, pages = paginate(:board_entry,
                                :per_page =>options[:per_page],
                                :order =>"last_updated DESC,board_entries.id DESC",
                                :conditions=> find_params[:conditions],
                                :include => find_params[:include] | [ :state ])

    locals = {
      :id_name => 'not_reading_blogs',
      :title_name => '未読記事の一覧',
      :pages => pages,
      :pages_obj => pages_obj,
      :symbol2name_hash => BoardEntry.get_symbol2name_hash(pages)
    }
  end

  def current_user_antennas_as_json
    antennas = Antenna.all(:conditions => ["user_id = ?" , current_user.id])
    result = {
      :antenna_list => antennas.map do |antenna|
        { :name => antenna.name, :url => url_for(:controller => :feed, :action => :user_antenna, :id => antenna.id) }
      end
    }.to_json
  end
end

