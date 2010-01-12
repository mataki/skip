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

class BoardEntriesController < ApplicationController

  verify :method => :post, :only => [ :ado_create_comment, :ado_create_nest_comment, :ado_pointup, :destroy_comment, :ado_edit_comment, :toggle_hide  ],
         :redirect_to => { :action => :index, :controller => "/mypage" }

  after_filter :make_comment_message, :only => [ :ado_create_comment, :ado_create_nest_comment ]

  # 巨大化表示
  def large
    unless @entry = check_entry_permission
      render :text => _("Invalid operation.")
      return false
    end

    render :layout=>false
  end

  # ルートコメントの作成
  def ado_create_comment
    if params[:board_entry_comment] == nil or params[:board_entry_comment][:contents] == ""
      render(:text => _('Invalid parameter(s) detected.'), :status => :bad_request) and return
    end

    # TODO 権限のあるBoardEntryを取得するnamed_scopeに置き換える
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, {:id => params[:id]})
    unless @board_entry = BoardEntry.find(:first,
                                          :conditions => find_params[:conditions],
                                          :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      render(:text => _('Target %{target} inexistent.')%{:target => _('board entry')}, :status => :bad_request) and return
    end

    params[:board_entry_comment][:user_id] = session[:user_id]
    comment = @board_entry.board_entry_comments.create(params[:board_entry_comment])
    unless comment.errors.empty?
      render(:text => _('Failed to save the data.'), :status => :bad_request) and return
    end

    render :partial => "board_entry_comment", :locals => { :comment => comment }
  end

  # ネストコメントの作成
  def ado_create_nest_comment
    begin
      parent_comment = BoardEntryComment.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      render(:text => _('Parent comment could not be found. Try reloading the page.'), :status => :not_found) and return
    end

    if params[:contents].blank?
      render(:text => _('Comment body is mandatory.'), :status => :bad_request) and return
    end

    # TODO 権限のあるBoardEntryを取得するnamed_scopeに置き換える
    @board_entry = parent_comment.board_entry
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, {:id => @board_entry.id})
    unless @board_entry = BoardEntry.find(:first,
                                          :conditions => find_params[:conditions],
                                          :include => find_params[:include] | [ :user, :board_entry_comments, :state ])
      render(:text => _('Target %{target} inexistent.')%{:target => _('board entry')}, :status => :bad_request) and return
    end

    comment = parent_comment.children.create(:board_entry_id => parent_comment.board_entry_id,
                                             :contents => params["contents"],
                                             :user_id => session[:user_id])
    unless comment.errors.empty?
      render(:text => _('Failed to save the data.'), :status => :bad_request) and return
    end
    render :partial => "board_entry_comment", :locals => { :comment => parent_comment.children.last, :level => params[:level].to_i }
  end

  def ado_pointup
    board_entry = BoardEntry.find(params[:id])
    unless board_entry.point_incrementable?(current_user)
      render :text => _('Operation unauthorized.'), :status => :forbidden and return
    end
    board_entry.state.increment!(:point)
    render :text => "#{board_entry.point} #{ERB::Util.html_escape(Admin::Setting.point_button)}"
  rescue ActiveRecord::RecordNotFound => ex
    render :text => _('Target %{target} inexistent.')%{:target => _('board entry')}, :status => :not_found and return
  end

  def destroy_comment
    @board_entry_comment = BoardEntryComment.find(params[:id])
    board_entry = @board_entry_comment.board_entry

    # 権限チェック
    authorize = false
    authorize = true if session[:user_symbol] == board_entry.symbol

    if current_user.group_symbols.include?(board_entry.symbol)
      if current_user.group_symbols.include?(board_entry.user_id)
        authorize = true
      elsif board_entry.publicate?(current_user.belong_symbols)
        authorize = true
      end
    else
      if session[:user_id] == @board_entry_comment.user_id && board_entry.publicate?(current_user.belong_symbols)
        authorize = true
      end
    end

    redirect_to_with_deny_auth and return unless authorize

    if @board_entry_comment.children.size == 0
      @board_entry_comment.destroy
      flash[:notice] = _("Comment was successfully deleted.")
    else
      flash[:warn] = _("This comment cannot be deleted since it has been commented.")
    end
    redirect_to :action => "forward", :id => @board_entry_comment.board_entry.id
  rescue ActiveRecord::RecordNotFound => ex
    flash[:warn] = _("Comment seems have already deleted.")
    redirect_to :controller => "mypage", :action => "index"
  end

  # ajax_action
  def ado_edit_comment
    begin
      comment = BoardEntryComment.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      render(:text => _('Target %{target} inexistent.')%{:target => _('board entry comment')}, :status => :bad_request) and return
    end
    unless comment.editable? current_user
      render(:text => _('Operation unauthorized.'), :status => :bad_request) and return
    end

    comment.update_attribute :contents, params[:comment][:contents]
    render :partial => "comment_contents", :locals =>{ :comment => comment }
  end

  def forward
    begin
      entry = BoardEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      flash[:warn] = _("Specified page does not exist.")
      redirect_to :controller => 'mypage', :action => ''
      return false
    end

    forward_hash = { 'uid' => { :controller => 'user',  :id =>"blog" },
                     'gid' => { :controller => 'group', :id =>'bbs'  } }

    flash.keep(:notice)
    flash.keep(:warn)
    redirect_to :controller => forward_hash[entry.symbol_type][:controller],
                :action     => entry.symbol_id,
                :id         => forward_hash[entry.symbol_type][:id],
                :entry_id   => entry.id
  end

  def toggle_hide
    @board_entry = BoardEntry.accessible(current_user).find params[:id]
    if @board_entry.toggle_hide(current_user)
      render :text => _("Entry was successfully set to %{operation}.") % { :operation => _("BoardEntry|Open|#{!@board_entry.hide}") }
    else
      render :text => _('Failed to update status.') + " : " + @board_entry.errors.full_messages.to_s, :status => :bad_request
    end
  end

private
  def make_comment_message
    return unless @board_entry
    unless @board_entry.writer?(session[:user_id])
      SystemMessage.create_message :message_type => 'COMMENT', :user_id => @board_entry.user.id, :message_hash => {:board_entry_id => @board_entry.id}
    end
  end

end
