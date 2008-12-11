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

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'fileutils'

class BatchMakeCache < BatchBase
  include ERB::Util

  # make_cachesから始まる名前のメソッドを次々と実行
  def self.execute options
    cache_path = options[:path]

    maker = self.new()
    maker.public_methods.each do |method|
      if method.index("make_caches_") == 0
        contents_type = method.gsub("make_caches_", "")
        maker.send(method, contents_type, cache_path, options[:time])
      end
    end
    File.symlink( ENV['SHARE_FILE_PATH'],"#{cache_path}/share_file" ) unless FileTest.symlink?("#{cache_path}/share_file")
  end

  # entry用
  def make_caches_entry(contents_type, cache_path, border_time)
    # 全部includeした状態でwhere句をつけると、コメントが複数ついていてひとつだけ15分前の場合、
    # その最新のコメントだけがincludeされた状態のentryオブジェクトになるので、ここではentry_idだけ取り出してwhere条件にする方法にした
    conditions = ["updated_on > ?", border_time]
    new_ids = BoardEntry.find(:all, :select => "id", :conditions => conditions).map{|entry| entry.id}
    new_ids += BoardEntryComment.find(:all, :select => "board_entry_id", :conditions => conditions).map{|comment| comment.board_entry_id}
    new_ids += EntryTrackback.find(:all, :select => "board_entry_id", :conditions => conditions).map{|trackback| trackback.board_entry_id}
    return if new_ids.size < 1
    entries = BoardEntry.find(:all,
                              :include => [:user, {:board_entry_comments => :user}, {:entry_trackbacks => {:tb_entry => :user}}],
                              :conditions =>["board_entries.id in (?)", new_ids.uniq])
    entries.each do |entry|
      publication_symbols = entry.entry_publications.map{|publication| publication.symbol}.join(',')
      body_lines = []
      body_lines << h(entry.title)
      body_lines << h(entry.category)
      body_lines << h(entry.user.name)
      body_lines << entry.contents

      entry.board_entry_comments.each do|comment|
        body_lines << h(comment.user.name)
        body_lines << comment.contents
      end
      entry.entry_trackbacks.each do |trackback|
        body_lines << h(trackback.tb_entry.user.name)
        body_lines << trackback.tb_entry.title
      end

      contents = create_contents(:title => entry.title,
                                 :body_lines => body_lines )

      meta = create_meta(:contents_type => contents_type,
                         :title => entry.title,
                         :publication_symbols => publication_symbols,
                         :link_url => "/page/#{entry.id}",
                         :icon_type => 'report' )

      output_file(cache_path, contents_type, entry.id , contents, meta)
    end
  end

  # ブックマーク用
  def make_caches_bookmark(contents_type, cache_path, border_time)
    new_ids = BookmarkComment.find(:all, :select => "bookmark_id",
                                   :conditions => ["updated_on > ?", border_time]).map{|comment| comment.bookmark_id}
    return if new_ids.size < 1
    bookmarks = Bookmark.find(:all, :include => [{:bookmark_comments => :user}], :conditions =>["bookmarks.id in (?)", new_ids.uniq])
    bookmarks.each do |bookmark|
      body_lines = []
      publication_symbols = bookmark.bookmark_comments.all?{|comment| !comment.public} ? [] : ["sid:allusers"]
      body_lines << h(bookmark.title)

      body_lines << bookmark.url
      bookmark.bookmark_comments.each do|comment|
        publication_symbols << "uid:#{h(comment.user.uid)}"
        next unless comment.public
        body_lines << h(comment.updated_on.strftime("%Y年%m月%d日"))
        body_lines << h(comment.user.name)
        body_lines << h(comment.tags)
        body_lines << h(comment.comment)
      end

      contents = create_contents(:title => bookmark.title,
                                 :body_lines => body_lines)

      meta = create_meta(:contents_type => contents_type,
                         :publication_symbols => publication_symbols.join(','),
                         :link_url => "/bookmark/show/#{bookmark.url}",
                         :title => bookmark.title,
                         :icon_type => 'tag_blue')

      output_file(cache_path, contents_type, bookmark.id, contents, meta)
    end
  end

  # groupのサマリ用
  def make_caches_group(contents_type, cache_path, border_time)
    groups = Group.find(:all, :conditions => ["updated_on > ?", border_time])
    groups.each do |group|
      body_lines = []
      body_lines << group.description

      contents = create_contents(:title => group.name,
                                 :body_lines => body_lines)

      meta = create_meta(:contents_type => contents_type,
                             :publication_symbols => "sid:allusers",
                             :link_url => "/group/#{group.gid}",
                             :title => group.name,
                             :icon_type => 'group')

      output_file(cache_path, contents_type, group.id, contents, meta)
    end
  end

  # userのプロフィール用
  def make_caches_user(contents_type, cache_path, border_time)
    users = User.find(:all, :include => ['user_profile_values'], :conditions => ["updated_on > ?", border_time])
    users.each do |user|
      body_lines = []
      body_lines << h(user.uid)
      body_lines << h(user.name)
      body_lines << h(user.code)
      body_lines << h(user.email)
      body_lines << h(user.section)

      user.user_profile_values.each do |profile|
        body_lines << h(profile.value)
      end

      contents = create_contents(:title => user.name,
                                 :body_lines => body_lines)

      meta = create_meta(:contents_type => contents_type,
                         :publication_symbols => "sid:allusers",
                         :link_url => "/user/#{user.uid}",
                         :title => user.name,
                         :icon_type => 'user_suit')

      output_file(cache_path, contents_type, user.id, contents, meta)
    end
  end

  def make_caches_share_file(contents_type, cache_path, border_time)
    share_files = ShareFile.find(:all, :conditions => ["date > ?", border_time])
    share_files.each do |file|
      publication_symbols = file.share_file_publications.map{ |pf| pf.symbol }
      publication_symbols << file.owner_symbol unless publication_symbols == ['sid:allusers']
      meta = create_meta(:contents_type => contents_type,
                         :publication_symbols => publication_symbols.join(','),
                         :link_url => "/#{file.owner_symbol_type}/#{file.owner_symbol_id}/files/#{file.file_name}",
                         :title => file.file_name,
                         :icon_type => 'disk_multiple')

      target_dir = "#{cache_path}_meta/share_file/#{file.owner_symbol_type}/#{file.owner_symbol_id}"
      FileUtils.mkdir_p target_dir
      File.open("#{target_dir}/#{file.file_name}", "w"){ |file| file.write(meta) }
    end
  end

  # キャッシュの中身を生成するメソッド
  #   title               :ヘッダのタイトル
  #   body_lines          :本文になる文章のArray
  def create_contents(params)
    return <<-EOS
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>#{h(params[:title])}</title>
</head>
<body>
#{params[:body_lines].join("\n")}
</body>
</html>
    EOS
  end
  # メタ情報を生成するメソッド
  #   title               :ヘッダのタイトル タイトル内に': 'があるとyaml形式と読み込まれるためスペースを削除
  #   contents_type       :コンテンツ種別
  #   publication_symbols :公開範囲
  #   link_url            :リンク
  #   icon_type           :検索表示に利用するiconのファイル名
  def create_meta(params)
    return <<-EOS
title: #{URI.encode(URI.encode(params[:title]), /[\&|\+|\=|!|~|'|(|)|;|\/|?|:|$|,|\[|\]|]/)}
contents_type: #{params[:contents_type]}
publication_symbols: #{params[:publication_symbols]}
link_url: #{root_url.chop}#{params[:link_url]}
icon_type: #{params[:icon_type]}
    EOS
  end

  # ファイルに出力
  def output_file(path, contents_type, contents_id, contents, meta)
    dir_id = (contents_id/1000).to_s.rjust(4,'0')
    target_dir = "#{path}/#{contents_type}/#{dir_id}"
    target_meta_dir = "#{path}_meta/#{contents_type}/#{dir_id}"
    FileUtils.mkdir_p(target_dir)
    FileUtils.mkdir_p(target_meta_dir)
    File.open("#{target_dir}/#{contents_id}.html", "w"){ |file| file.write(contents) }
    File.open("#{target_meta_dir}/#{contents_id}.html", "w"){ |file| file.write(meta) }
  end
end

# シェルからパラメータを受け取って実行する部分
# パラメータは順不同、なくてもOK
# -all すべてのキャッシュを再作成
# -cache_path=キャッシュパス文字列
# 実行例 ruby batch_make_cache.rb -cache_path=/var/skip_caches/systest -all
# 時間を指定しなければ15分前以降に更新されたもののキャッシュを生成する
time = 15.minutes.ago
ARGV.each do |arg|
  if arg.index("-time=")
    time = eval(arg.split('=').last).minutes.ago if arg.split('=').size > 1
  end
end
time = 100.years.ago if ARGV.include?("-all")

path = ""
ARGV.each do |arg|
  if arg.index("-cache_path=")
    path += arg.split('=').last if arg.split('=').size > 1
    break
  end
end
if path.empty?
  BatchMakeCache::log_error "キャッシュの生成先が指定されていません"
else
  BatchMakeCache.execution({ :time => time, :path => path })
end
