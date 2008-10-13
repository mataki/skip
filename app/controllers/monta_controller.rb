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

class MontaController < ApplicationController
  layout false
  protect_from_forgery :except => [:execute, :ado_view_contents]

  def execute_monta
    unless check_entry_permission
      render :text => "不正な操作です"
      return false
    end
    return unless get_board_entry

    @first_url = url_for(:action => :ado_view_contents, :id => @board_entry.id)
    render :action => :monta
  end

  def ado_view_contents
    unless check_entry_permission
      render :text => "不正な操作です"
      return false
    end
    return unless get_board_entry

    index = params[:index].to_i
    index = 0 if index < 0

    arr, counter_array = divide_text @board_entry.contents

    if index < arr.size
      @content, @img_id_arr = decorate_str arr[index], @board_entry.id, @board_entry.user_id
      @hidden_content = replace_img_id @content, @img_id_arr
      @counter_value = "[#{counter_array[index]}/#{counter_array.last}]"
    else
      index = arr.size
      @content = @hidden_content = '<a href="#" onclick="window.close();">おしまい</a>'
    end

    @next_url = url_for(:action => 'ado_view_contents', :id => @board_entry.id, :index => index+1)
    @prev_url = url_for(:action => 'ado_view_contents', :id => @board_entry.id, :index => index-1)
  end

private
  def decorate_str(str, board_entry_id, board_entry_user_id)
    view_str = ERB::Util.html_escape(str)

    # 黄色い付箋紙を追加
    if view_str.match(/\[\[.+?\]\]/)
      view_str = view_str.gsub("[[", "<span id='monta' style='background-color: #FFFF00; color: #FFFF00;'> ").gsub("]]", "</span>")
    end

    # 画像を追加
    regex_type = /\{\{.+?\}\}/
    img_id_arr = []
    if image_name = view_str.match(regex_type)
      image_name = board_entry_id.to_s + "_" + image_name.to_s.gsub("{{", "").gsub("}}", "")
      img_url = url_for(:controller=>'image', :action=>'show', :path=>File.join('board_entries', board_entry_user_id.to_s, image_name))

      view_str = view_str.gsub(regex_type, "<img id='image_#{image_name}' src='#{img_url}' />")
      img_id_arr << "image_#{image_name}"
    end

    # テキストのレイアウト指定
    if text_align = view_str.match(/\|\|.+?\|\|/)
      case text_align.to_s[2..-3]
      when "left"
        @text_align = "left"
      when "right"
        @text_align = "right"
      else
        @text_align = "center"
      end
      view_str = view_str.gsub(text_align.to_s+"\r\n", "")
    end
    return view_str.gsub("\r\n", "<br/>"), img_id_arr
  end

  def replace_img_id content, img_id_arr
    hidden_content = content
    img_id_arr.each do |img_id|
      hidden_content = hidden_content.gsub("id='#{img_id}'", "id='hidden_#{img_id}'");
    end
    return ERB::Util.html_escape(hidden_content)
  end

  def divide_text text
    line_count, content_array, counter_array = 1, [], []

    text.split(/[\r\n]{3,}/).each do |src_text|
      tmp_text = src_text
      content_array << src_text
      counter_array << line_count
      while tmp_text.match(/\[\[.+?\]\]/)
        tmp_text = tmp_text.sub("[[","").sub("]]","")
        content_array << tmp_text
        counter_array << line_count
      end
      line_count += 1
    end
    return content_array, counter_array
  end

  def get_board_entry
    begin
      @board_entry = BoardEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

end
