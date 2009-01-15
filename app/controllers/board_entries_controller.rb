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

class BoardEntriesController < ApplicationController

  verify :method => :post, :only => [ :ado_create_comment, :ado_create_nest_comment, :ado_pointup, :destroy_comment, :ado_edit_comment ], 
         :redirect_to => { :action => :index }

  after_filter :make_comment_message, :only => [ :ado_create_comment, :ado_create_nest_comment ]

  # 巨大化表示
  def large
    unless @entry = check_entry_permission
      render :text => "不正な操作です"
      return false
    end

    render :layout=>false
  end

  # ルートコメントの作成
  def ado_create_comment
    if params[:board_entry_comment] == nil or params[:board_entry_comment][:contents] == ""
      render :nothing => true
      return false
    end

    find_params = BoardEntry.make_conditions(login_user_symbols, {:id => params[:id]})
    unless @board_entry = BoardEntry.find(:first,
                                          :conditions => find_params[:conditions],
                                          :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      render :nothing => true
      return false
    end

    params[:board_entry_comment][:user_id] = session[:user_id]
    comment = @board_entry.board_entry_comments.create(params[:board_entry_comment])
    unless comment.errors.empty?
      render :nothing => true
      return false
    end

    render :partial => "board_entry_comment", :locals => { :comment => comment }
  end

  # ネストコメントの作成
  def ado_create_nest_comment
    begin
      parent_comment = BoardEntryComment.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      render(:text => _('親コメントが存在しません。再読み込みして下さい。'), :status => :not_found) and return
    end

    if params[:contents].blank?
      render(:text => _('コメントの入力は必須です。'), :status => :bad_request) and return
    end

    @board_entry = parent_comment.board_entry
    find_params = BoardEntry.make_conditions(login_user_symbols, {:id => @board_entry.id})
    unless @board_entry = BoardEntry.find(:first,
                                          :conditions => find_params[:conditions],
                                          :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      render(:text => _('コメント対象の記事は存在しません。'), :status => :not_found) and return
    end

    comment = parent_comment.children.create(:board_entry_id => parent_comment.board_entry_id,
                                             :contents => params["contents"],
                                             :user_id => session[:user_id])
    unless comment.errors.empty?
      render(:text => _('保存に失敗しました。'), :status => :bad_request) and return
    end
    render :partial => "board_entry_comment", :locals => { :comment => parent_comment.children.last, :level => params[:level].to_i }
  end

  def ado_pointup
    board_entry = BoardEntry.find(params[:id])
    unless board_entry.point_incrementable?(current_user)
      render :text => _('この操作は、許可されていません。'), :status => :forbidden and return
    end
    board_entry.state.increment!(:point)
    render :text => "#{board_entry.point} #{ERB::Util.html_escape(Admin::Setting.point_button)}"
  rescue ActiveRecord::RecordNotFound => ex
    render :text => _('対象の記事が存在しません。'), :status => :not_found and return
  end

  def destroy_comment
    @board_entry_comment = BoardEntryComment.find(params[:id])
    board_entry = @board_entry_comment.board_entry

    # 権限チェック
    authorize = false
    authorize = true if session[:user_symbol] == board_entry.symbol

    if login_user_groups.include?(board_entry.symbol)
      if login_user_groups.include?(board_entry.user_id)
        authorize = true
      elsif board_entry.publicate?(login_user_symbols)
        authorize = true
      end
    else
      if session[:user_id] == @board_entry_comment.user_id && board_entry.publicate?(login_user_symbols)
        authorize = true
      end
    end

    redirect_to_with_deny_auth and return unless authorize

    if @board_entry_comment.children.size == 0
      @board_entry_comment.destroy
      flash[:notice] = "コメントを削除しました。"
    else
      flash[:warning] = "このコメントに対するコメントがあるため削除できません。"
    end
    redirect_to :action => "forward", :id => @board_entry_comment.board_entry.id
  rescue ActiveRecord::RecordNotFound => ex
    flash[:warning] = "コメントは既に削除された模様です"
    redirect_to :controller => "mypage", :action => "index"
  end

  # ajax_action
  def ado_edit_comment
    comment = BoardEntryComment.find(params[:id])
    board_entry = comment.board_entry

    # 権限チェック
    authorize = false

    if comment.user_id == session[:user_id]
      if board_entry.symbol == session[:user_symbol]
        authorize = true
      end
      if login_user_groups.include?(board_entry.symbol)
        if session[:user_id] == board_entry.user_id
          authorize = true
        elsif board_entry.publicate?(login_user_symbols)
          authorize = true
        end
      elsif board_entry.publicate?(login_user_groups)
        authorize = true
      end
    end

    redirect_to_with_deny_auth and return unless authorize


    comment.update_attribute :contents, params[:comment][:contents]
    render :partial => "comment_contents", :locals =>{ :comment => comment }
  end

  def forward
    begin
      entry = BoardEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      flash[:warning] = "指定のページは存在していません。"
      redirect_to :controller => 'mypage', :action => ''
      return false
    end

    forward_hash = { 'uid' => { :controller => 'user',  :id =>"blog" },
                     'gid' => { :controller => 'group', :id =>'bbs'  } }

    flash.keep(:notice)
    flash.keep(:warning)
    redirect_to :controller => forward_hash[entry.symbol_type][:controller],
                :action     => entry.symbol_id,
                :id         => forward_hash[entry.symbol_type][:id],
                :entry_id   => entry.id
  end

private
  def make_comment_message
    return unless @board_entry
    unless @board_entry.writer?(session[:user_id])
      link_url = url_for(@board_entry.get_url_hash.update({:only_path => true}))
      Message.save_message("COMMENT", @board_entry.user_id, link_url, @board_entry.title)
    end
  end

end
