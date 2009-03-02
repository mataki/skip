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

require 'uri'
class BookmarkController < ApplicationController
  verify :method => :post, :only => [:update, :destroy, :ado_set_stared ], :redirect_to => { :action => :show }

  before_filter :check_params, :only => [:new, :edit]

  protect_from_forgery :except => [:new]

  # ブックマークレット用
  def new
    user_tags, other_tags, your_tags = prepare_bookmark params
    @bookmarklet = true
    render(:layout => 'subwindow', :partial => 'new',
           :locals => {
             :user_tags_array => user_tags,
             :other_tags_array => other_tags,
             :your_tags_array => your_tags,
             :layout => "subwindow"
           })
  end

  # ブックマーク更新画面の表示（存在しない場合は作成）
  def edit
    user_tags, other_tags, your_tags = prepare_bookmark params

    render(:layout => 'dialog', :partial => 'new',
           :locals => {
             :user_tags_array => user_tags,
             :other_tags_array => other_tags,
             :your_tags_array => your_tags,
             :layout => "dialog"
           })
  end

  # ブックマークの更新（存在しない場合は作成）
  def update
    url = params[:bookmark][:url]

    unless check_url_format? url
      messages = []
      messages << 'このURLは、ブックマークできません。'
      render :partial => "system/error_messages_for", :locals=> { :messages => messages }
      return
    end

    @bookmark = Bookmark.find_by_url(url) || Bookmark.new
    @bookmark.attributes = params[:bookmark]

    @bookmark_comment = @bookmark.bookmark_comments.find(:first, :conditions => ["bookmark_comments.user_id = ?", session[:user_id]]) || @bookmark.bookmark_comments.build
    @bookmark_comment.attributes = params[:bookmark_comment]
    @bookmark_comment.user_id ||= session[:user_id]
    @bookmark_comment.public ||= true if @bookmark.is_type_user?

    is_new_record = @bookmark.new_record?
    Bookmark.transaction do
      # 親が存在しない場合は、親保存時に子も保存される。既存の親の場合は親を保存しても子が保存されないので子のみ保存
      @bookmark_comment.save! unless is_new_record
      @bookmark.save!
      if @bookmark.is_type_user?
        uid = @bookmark.url.slice(/^\/user\/(.*)/, 1)
        user = User.find_by_uid(uid)
        link_url = url_for(:controller => 'user', :uid => uid,
                           :action => 'social', :menu => 'social_postit' , :only_path => true)
        Message.save_message("POSTIT", user.id, link_url)
      end
    end

    flash[:notice] = is_new_record ? 'ブックマークを登録しました。' : 'ブックマークを更新しました。' if params[:layout] == "dialog"
    render :text => 'success'
  rescue ActiveRecord::RecordInvalid => ex
    messages = []
    messages.concat @bookmark.errors.full_messages.reject{|msg| msg.include?("Bookmark comments")} unless @bookmark.valid?
    messages.concat @bookmark_comment.errors.full_messages unless @bookmark_comment.valid?

    render :partial => "system/error_messages_for", :locals=> { :messages => messages }
  end

  def ado_get_title
    render :text => Bookmark.get_title_from_url(params[:url])
  end

  # tab_menu
  def show
    uri = params[:uri] ? URI.decode(params[:uri]) : ""
    uri.gsub!('+', ' ')
    unless @bookmark = Bookmark.find_by_url(uri, :include => :bookmark_comments )
      flash[:warning] = _("指定のＵＲＬは誰もブックマークしていません。")
      redirect_to :controller => 'mypage', :action => 'index'
      return
    end

    @main_menu = 'ブックマーク'
    @title = 'ブックマーク[' + @bookmark.title + ']'
    @tab_menu_source = [ {:label => _('ブックマークコメント'), :options => {:action => 'show'}} ]
    @tab_menu_option = { :uri => @bookmark.url }

    # TODO: SQLを発行しなくても判断できるのでrubyで処理する様に
    comment =  BookmarkComment.find(:first,
                                    :conditions => ["bookmark_id = ? and user_id = ?", @bookmark.id, session[:user_id]])

    @tags = BookmarkComment.get_tagcloud_tags @bookmark.url

    @create_button_show =  comment ? false : true
  end

  # ブックマークコメントの削除
  def destroy
    comment = BookmarkComment.find(params[:comment_id])

    # 権限チェック
    redirect_to_with_deny_auth and return unless comment.user_id == session[:user_id]

    comment.destroy
    flash[:notice] = '削除しました。'
    redirect_to  :action =>'show', :uri => comment.bookmark.url
  end

  #ユーザのブックマークコメント一覧表示(ユーザのページからのリンクでくる)
  def list
    redirect_to_with_deny_auth and return if not parent_controller

    @main_menu = parent_controller.send!(:main_menu)
    @title = parent_controller.send!(:title)
    @tab_menu_source = parent_controller.send!(:tab_menu_source)
    @tab_menu_option = parent_controller.send!(:tab_menu_option)

    params[:user_id] = parent_controller.params[:user_id]
    params[:page] = parent_controller.params[:page]
    params[:keyword] = parent_controller.params[:keyword]
    params[:category] = parent_controller.params[:category]
    params[:type] = parent_controller.params[:type]

    #タグ検索用
    @tags = BookmarkComment.get_tags params[:user_id]

    #結果表示用
    conditions = BookmarkComment.make_conditions_for_comment(session[:user_id], params)
    @pages, @bookmark_comments = paginate(:bookmark_comments,
                                          :per_page => 20,
                                          :conditions => conditions,
                                          :order =>'bookmark_comments.created_on DESC' ,
                                          :include => :bookmark)
    unless @bookmark_comments && @bookmark_comments.size > 0
      if params[:commit] || params[:category] || params[:type]
        flash.now[:notice] = '該当するブックマークはありませんでした。'
      else
        flash.now[:notice] = '現在ブックマークは登録されていません。'
      end
    end

    params[:controller] = parent_controller.params[:controller]
    params[:action] = parent_controller.params[:action]
  end

  def ado_set_stared
    bookmark_comment = BookmarkComment.find_by_id(params[:bookmark_comment_id])
    # 権限チェック
    unless bookmark_comment.user_id == session[:user_id]
      render :nothing => true
      return false
    end
    bookmark_comment.update_attribute(:stared, params[:stared])
    render :partial => "bookmark/stared", :locals => {:bookmark_comment => bookmark_comment}
  end

  def bookmark_count
    @bookmark = Bookmark.find(:all,
                              :select => "bookmark_comments_count",
                              :conditions => ["url = ?", params[:uri]])
    count = @bookmark[0] ? @bookmark[0].bookmark_comments_count : 0
    render :text => count.to_s
  end


private
  def check_params
    unless params[:url] && check_url_format?(params[:url])
      flash[:warning] = "そのURLは有効ではありません。"
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

  def check_url_format? url
    # 社内用URLのチェックは、bookmarkと重複している。
    ((url =~ /^\/user\/.*/) || (url =~ /^\/page\/.*/) || url =~ /^https?:\/\/.*/) && !(url =~ /.*javascript:.*/)
  end

  def prepare_bookmark params
    conditions = ["bookmark_comments.user_id = ? and bookmarks.url = ?"]
    conditions << session[:user_id] << params[:url]
    @bookmark_comment = BookmarkComment.find(:first,
                                             :conditions => conditions,
                                             :include => [:bookmark])
    if @bookmark_comment
      @bookmark = @bookmark_comment.bookmark
    else
      @bookmark_comment = BookmarkComment.new(:public => true)

      unless @bookmark = Bookmark.find_by_url(params[:url])
        @bookmark = Bookmark.new(:url => params[:url], :title => params[:title].toutf8)
      end
    end

    user_tags = BookmarkComment.get_tagcloud_tags params[:url]
    user_tags.map! {|tag| tag.name }

    other_tags = BookmarkComment.get_bookmark_tags @bookmark.is_type_user?
    other_tags.map! {|tag| tag.name }
    other_tags = other_tags - user_tags

    your_tags = BookmarkComment.get_tags session[:user_id], 20
    your_tags.map! {|tag| tag.name }
    your_tags = your_tags - user_tags
    your_tags = your_tags - other_tags

    return user_tags, other_tags, your_tags
  end
end
