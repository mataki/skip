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

require File.expand_path(File.dirname(__FILE__) + "/batch_base")
require 'fileutils'

class BatchMakeCache < BatchBase
  include ERB::Util
  @border_time = :none

  def initialize interval = nil
    if interval && interval.is_a?(Integer)
      @border_time = interval.ago
    end
  end
  # make_cachesから始まる名前のメソッドを次々と実行
  def self.execute options
    cache_path = get_cache_path

    maker = self.new(options[:time])
    maker.public_methods.each do |method|
      if method.index("make_caches_") == 0
        contents_type = method.gsub("make_caches_", "")
        maker.send(method, contents_type, cache_path)
      end
    end
    File.symlink( SkipEmbedded::InitialSettings['share_file_path'],"#{cache_path}/share_file" ) unless FileTest.symlink?("#{cache_path}/share_file")
  end

  def self.get_cache_path
    if cache_path = SkipEmbedded::InitialSettings['cache_path']
      cache_path
    else
      raise StandardError, "Invalid cache path (cache_path: #{cache_path}). Please check your initial_settings.yml."
    end
  end

  # entry用
  def make_caches_entry(contents_type, cache_path)
    entries = load_not_cached_entries
    entries.each do |entry|
      contents = create_contents(:title => entry.title,
                                 :body_lines => entry_body_lines(entry) )

      publication_symbols = entry.entry_publications.map{|publication| publication.symbol}.join(',')
      meta = create_meta(:contents_type => contents_type,
                         :title => entry.title,
                         :publication_symbols => publication_symbols,
                         :link_url => "/page/#{entry.id}",
                         :icon_type => 'report' )

      output_file(cache_path, contents_type, entry.id , contents, meta)
    end
  end

  # ブックマーク用
  def make_caches_bookmark(contents_type, cache_path)
    bookmarks = load_not_cached_bookmarks
    bookmarks.each do |bookmark|
      contents = create_contents(:title => bookmark.title,
                                 :body_lines => bookmark_body_lines(bookmark))

      meta = create_meta(:contents_type => contents_type,
                         :publication_symbols => bookmark_publication_symbols(bookmark).join(','),
                         :link_url => "/bookmark/show/#{convert_bookmark_url(bookmark.url)}",
                         :title => bookmark.title,
                         :icon_type => 'tag_blue')

      output_file(cache_path, contents_type, bookmark.id, contents, meta)
    end
  end

  def convert_bookmark_url url
    URI.encode( url, Regexp.new("[^#{URI::PATTERN::ALNUM}]") )
  end

  # groupのサマリ用
  def make_caches_group(contents_type, cache_path)
    conditions =
      if @border_time.is_a?(Time)
        ["updated_on > ?", @border_time]
      else
        []
      end
    groups = Group.active.find(:all, :conditions => conditions)
    groups.each do |group|
      contents = create_contents(:title => group.name,
                                 :body_lines => [group.description])

      meta = create_meta(:contents_type => contents_type,
                             :publication_symbols => "sid:allusers",
                             :link_url => "/group/#{group.gid}",
                             :title => group.name,
                             :icon_type => 'group')

      output_file(cache_path, contents_type, group.id, contents, meta)
    end
  end

  # userのプロフィール用
  def make_caches_user(contents_type, cache_path)
    conditions =
      if @border_time.is_a?(Time)
        ["updated_on > ?", @border_time]
      else
        []
      end
    users = User.find(:all, :include => ['user_profile_values'], :conditions => conditions)
    users.each do |user|
      contents = create_contents(:title => user.name,
                                 :body_lines => user_body_lines(user))

      meta = create_meta(:contents_type => contents_type,
                         :publication_symbols => "sid:allusers",
                         :link_url => "/user/#{user.uid}",
                         :title => user.name,
                         :icon_type => 'user_suit')

      output_file(cache_path, contents_type, user.id, contents, meta)
    end
  end

  def make_caches_share_file(contents_type, cache_path)
    conditions =
      if @border_time.is_a?(Time)
        ["date <= ? AND updated_at > ?", @border_time, @border_time]
      else
        []
      end
    share_files = ShareFile.find(:all, :conditions => conditions)
    share_files.each do |file|
      publication_symbols = file.share_file_publications.map{ |pf| pf.symbol }
      meta = create_meta(:contents_type => contents_type,
                         :publication_symbols => publication_symbols.join(','),
                         :link_url => "/#{file.owner_symbol_type}/#{file.owner_symbol_id}/files/#{file.file_name}",
                         :title => file.file_name,
                         :icon_type => 'disk_multiple')

      target_dir = "#{cache_path}_meta/share_file/#{file.owner_symbol_type}/#{file.owner_id}"
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
    { :title => params[:title].to_s,
      :contents_type => params[:contents_type],
      :publication_symbols => params[:publication_symbols],
      :link_url => root_url.chop + params[:link_url],
      :icon_type => params[:icon_type]
    }.to_yaml
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

  private
  def load_not_cached_entries
    # 全部includeした状態でwhere句をつけると、コメントが複数ついていてひとつだけ15分前の場合、
    # その最新のコメントだけがincludeされた状態のentryオブジェクトになるので、ここではentry_idだけ取り出してwhere条件にする方法にした
    conditions =
      if @border_time.is_a?(Time)
        ["updated_on > ?", @border_time]
      else
        []
      end
    new_ids = BoardEntry.find(:all, :select => "id", :conditions => conditions).map{|entry| entry.id}
    new_ids += BoardEntryComment.find(:all, :select => "board_entry_id", :conditions => conditions).map{|comment| comment.board_entry_id}
    new_ids += EntryTrackback.find(:all, :select => "board_entry_id", :conditions => conditions).map{|trackback| trackback.board_entry_id}
    return [] if new_ids.empty?
    BoardEntry.find(:all,
                    :include => [:user, {:board_entry_comments => :user}, {:entry_trackbacks => {:tb_entry => :user}}],
                    :conditions =>["board_entries.id in (?)", new_ids.uniq])
  end

  def entry_body_lines(entry)
    body_lines = []
    body_lines << h(entry.title)
    body_lines << h(entry.category)
    body_lines << h(entry.user.name)
    body_lines << (entry.editor_mode == 'hiki' ? convert_hiki_to_html(entry.contents) : entry.contents)

    entry.board_entry_comments.each do|comment|
      body_lines << h(comment.user.name)
      body_lines << convert_hiki_to_html(comment.contents)
    end
    entry.entry_trackbacks.each do |trackback|
      body_lines << h(trackback.tb_entry.user.name)
      body_lines << trackback.tb_entry.title
    end
    body_lines
  end

  def load_not_cached_bookmarks
    conditions =
      if @border_time.is_a?(Time)
        ["updated_on > ?", @border_time]
      else
        []
      end
    new_ids = BookmarkComment.find(:all, :select => "bookmark_id",
                                   :conditions => conditions).map{|comment| comment.bookmark_id}
    return [] if new_ids.empty?
    Bookmark.find(:all, :include => [{:bookmark_comments => :user}], :conditions =>["bookmarks.id in (?)", new_ids.uniq])
  end

  def bookmark_publication_symbols(bookmark)
    publication_symbols = bookmark.bookmark_comments.all?{|comment| !comment.public} ? [] : ["sid:allusers"]
    bookmark.bookmark_comments.each do|comment|
      publication_symbols << "uid:#{h(comment.user.uid)}"
    end
    publication_symbols
  end

  def bookmark_body_lines(bookmark)
    body_lines = []
    body_lines << h(bookmark.title)
    body_lines << bookmark.url
    bookmark.bookmark_comments.each do|comment|
      next unless comment.public
      body_lines << h(comment.updated_on.strftime("%Y年%m月%d日"))
      body_lines << h(comment.user.name)
      body_lines << h(comment.tags)
      body_lines << h(comment.comment)
    end
    body_lines
  end

  def user_body_lines(user)
    body_lines = []
    body_lines << h(user.uid)
    body_lines << h(user.name)
    body_lines << h(user.code)
    body_lines << h(user.email) unless Admin::Setting.hide_email
    body_lines << h(user.section)

    user.user_profile_values.each do |profile|
      body_lines << h(profile.value)
    end
    body_lines
  end

  def convert_hiki_to_html hiki_text
    HikiDoc.new((hiki_text || ''), Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
  end
end

# シェルからパラメータを受け取って実行する部分
# パラメータは順不同、なくてもOK
# -all すべてのキャッシュを再作成
# 実行例 ruby batch_make_cache.rb -all
# 時間を指定しなければ15分前以降に更新されたもののキャッシュを生成する
time = 15.minutes
ARGV.each do |arg|
  if arg.index("-time=")
    time = eval(arg.split('=').last).minutes if arg.split('=').size > 1
  end
end
time = nil if ARGV.include?("-all")

BatchMakeCache.execution({ :time => time }) unless RAILS_ENV == 'test'
