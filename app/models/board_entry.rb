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

class BoardEntry < ActiveRecord::Base
  include Publication
  include ActionController::UrlWriter

  belongs_to :user
  has_many :tags, :through => :entry_tags
  has_many :entry_tags, :dependent => :destroy
  has_many :entry_publications, :dependent => :destroy
  has_many :entry_editors, :dependent => :destroy
  has_many :entry_trackbacks, :dependent => :destroy
  has_many :to_entry_trackbacks, :class_name => "EntryTrackback", :foreign_key => :tb_entry_id, :dependent => :destroy
  has_many :board_entry_comments, :dependent => :destroy
  has_one  :state, :class_name => "BoardEntryPoint", :dependent => :destroy
  has_many :entry_accesses, :dependent => :destroy
  has_many :user_readings, :dependent => :destroy

  before_create :generate_next_user_entry_no
  after_destroy :cancel_mail

  validates_presence_of :title
  validates_length_of   :title, :maximum => 100

  validates_presence_of :contents
  validates_presence_of :date
  validates_presence_of :user_id

  attr_reader :owner
  attr_accessor :send_mail

  N_('BoardEntry|Entry type|DIARY')
  N_('BoardEntry|Entry type|GROUP_BBS')
  DIARY = 'DIARY'
  GROUP_BBS = 'GROUP_BBS'

  def validate
    symbol_type, symbol_id = Symbol::split_symbol self.symbol
    if self.entry_type == DIARY
      if symbol_type == "uid"
        errors.add_to_base(_("User does not exist.")) unless User.find_by_uid(symbol_id)
      else
        errors.add_to_base(_("Invalid user detected."))
      end
    elsif self.entry_type == GROUP_BBS
      if symbol_type == "gid"
        errors.add_to_base(_("Group does not exist.")) unless Group.active.find_by_gid(symbol_id)
      else
        errors.add_to_base(_("Invalid group detected."))
      end
    end

    Tag.validate_tags(category).each{ |error| errors.add(:category, error) }
  end

  def before_save
    square_brackets_tags
    parse_symbol_link
    self.contents = CGI.unescapeHTML(self.contents) if self.editor_mode == 'richtext'
  end

  def after_save
    Tag.create_by_string category, entry_tags
  end

  def after_create
    BoardEntryPoint.create(:board_entry_id=>id)
  end

  def permalink
    '/page/' + id.to_s
  end

  # ブログかどうか
  def diary?
    entry_type == DIARY
  end

  # 重要タグがついているもの
  def important?
    category.include?("[#{Tag::PRIORITY_TAG}]")
  end

  # 所属するグループの公開範囲により、記事の公開範囲を判定する
  def owner_is_public?
    Symbol.public_symbol_obj? symbol
  end

  # 検索条件の生成
  def self.make_conditions(login_user_symbols, options={})
    options.assert_valid_keys [:entry_type, :keyword, :id, :category, :categories, :recent_day, :symbol, :writer_id, :tag_words, :tag_select, :ids, :symbols, :exclude_entry_type, :publication_type]

    conditions_param = []

    # 公開条件（必須）
    conditions_state = "(entry_publications.symbol in (?))"
    conditions_param << login_user_symbols + [Symbol::SYSTEM_ALL_USER] # 全公開も見れる

    # 種別
    if entry_type = options[:entry_type]
      conditions_state << " and board_entries.entry_type= ? "
      conditions_param << entry_type
    end

    # 除外種別
    if entry_type = options[:exclude_entry_type]
      conditions_state << " and board_entries.entry_type <> ? "
      conditions_param << entry_type
    end

    # 公開範囲
    if publication_type = options[:publication_type]
      conditions_state << " and board_entries.publication_type= ? "
      conditions_param << publication_type
    end

    # 所有者条件
    # todo options[:symbol]を廃止し、:symbolsに統合（修正量が多いため9/21時点では見送り）
    options[:symbols] ||= []
    options[:symbols] = options[:symbols] | [options[:symbol]] if options[:symbol]
    if (symbols = options[:symbols]).size > 0
      conditions_state << " and board_entries.symbol in (?) "
      conditions_param << symbols
    end

    # 書いた人
    if writer_id = options[:writer_id]
      conditions_state << " and board_entries.user_id = ? "
      conditions_param << writer_id
    end

    # キーワード条件
    if keyword = options[:keyword] and !keyword.empty?
      conditions_state << " and (board_entries.title like ? or board_entries.contents like ? or board_entries.category like ?)"
      conditions_param << SkipUtil.to_like_query_string(keyword)
      conditions_param << SkipUtil.to_like_query_string(keyword)
      conditions_param << SkipUtil.to_like_query_string(keyword)
    end

    # id条件（一意）
    if id = options[:id]
      conditions_state << " and board_entries.id = ?"
      conditions_param << id
    end

    # id条件（複数）
    if ids = options[:ids]
      conditions_state << " and board_entries.id in (?)"
      conditions_param << ids
    end

    # カテゴリ
    if category = options[:category] and category != ''
      conditions_state << " and board_entries.category like ?"
      conditions_param << '%[' + category + ']%'
    end
    if categories = options[:categories] and !categories.empty?
      categories.each do |category|
        conditions_state << " and board_entries.category like ?"
        conditions_param << '%[' + category + ']%'
      end
    end

    #タグ
    if options[:tag_words] && options[:tag_select]
      words = options[:tag_words].split(',');
      if options[:tag_select] == "AND"
        words.each do |word|
          conditions_state << " and board_entries.category like ?"
          conditions_param << SkipUtil.to_like_query_string(word)
        end
      else
        words.each do |word|
          conditions_state << " and (" if word == words.first
          conditions_state << " board_entries.category like ? OR" if word != words.last
          conditions_state << " board_entries.category like ?)" if word == words.last
          conditions_param << SkipUtil.to_like_query_string(word)
        end
      end
    end


    # 最近の何日間条件
    if recent_day = options[:recent_day]
      conditions_state << " and last_updated >  ?"
#      conditions_state << " and board_entries.id >  ?"
      conditions_param << Date.today-recent_day
    end

    return {:conditions => conditions_param.unshift(conditions_state), :include => [:entry_publications] }
  end


  # 最新の一覧を取得（ブログでも掲示板でも。オーナーさえ決まればOK。）
  def self.find_visible(limit, login_user_symbols, owner_symbol)
    find_params = self.make_conditions(login_user_symbols, {:symbol => owner_symbol})
    return self.find(:all,
                     :limit=>limit,
                     :conditions => find_params[:conditions],
                     :order=>"last_updated DESC,board_entries.id DESC",
                     :include => find_params[:include] | [ :state, :board_entry_comments ])
  end

  def send_mail?
    true if send_mail == "1"
  end

  def get_around_entry(login_user_symbols)
    order_value = BoardEntry.find(:first, :select => 'last_updated+id as order_value', :conditions=>["id = ?", id]).order_value
    prev_entry = next_entry = nil
    find_params = BoardEntry.make_conditions(login_user_symbols, {:symbol=>symbol})
    find_params[:conditions] << order_value

    conditions_state = find_params[:conditions][0].dup

    find_params[:conditions][0] << " and (last_updated+board_entries.id)< ?"
    prev_entry = BoardEntry.find(:first, :conditions => find_params[:conditions], :include => find_params[:include], :order=>"last_updated+board_entries.id desc")

    find_params[:conditions][0] = conditions_state
    find_params[:conditions][0] << " and (last_updated+board_entries.id) > ?"
    next_entry = BoardEntry.find(:first, :conditions => find_params[:conditions], :include => find_params[:include], :order=>"last_updated+board_entries.id asc")

    return prev_entry, next_entry
  end

  def self.get_category_words(options={})
    options[:include] ||= []
    options[:select] = "id"

    # todo サブクエリ化 下にコメントアウトしてある方法でできる。が、現在の件数ではこちらの方が早い
    entry_ids = BoardEntry.find(:all, options).map{ |entry| entry.id }

    if entry_ids.size > 0
      Tag.find(:all,
               :select => "name",
               :conditions => ["entry_tags.board_entry_id in (?)", entry_ids],
               :joins => 'JOIN entry_tags ON tags.id = entry_tags.tag_id').map{ |tag| tag.name }.uniq.sort
    else
      return []
    end
  end

#  def self.get_category_words(options={})
#    options[:include] ||= []
#    options[:include] = options[:include] | [:entry_tags, :tags]
#
#    board_entries = BoardEntry.find(:all, options)
#    categories = []
#    board_entries.each do |entry|
#      entry.tags.each do |tag|
#        categories << tag.name
#      end
#    end
#    categories.uniq.sort
#  end


  def self.get_popular_tag_words()
    options = { :select => 'tags.name',
                :joins => 'JOIN tags ON entry_tags.tag_id = tags.id',
                :group => 'entry_tags.tag_id',
                :order => 'count(entry_tags.tag_id) DESC'}

    entry_tags = EntryTag.find(:all, options)
    tags = []
    entry_tags.each do |tag|
      tags << tag.name
    end
    return tags.uniq.first(40)
  end

  def self.get_categories_hash(login_user_symbols, options={})
    find_params = BoardEntry.make_conditions(login_user_symbols, options)
    categories = BoardEntry.get_category_words(find_params)
    categories_hash = {}

    categories_hash[:standard] = Tag.get_standard_tags
    categories_hash[:system] = Tag.get_system_tags
    categories_hash[:mine] = categories - (categories_hash[:standard] + categories_hash[:system])
    categories_hash[:user] = BoardEntry.get_category_words({:order=>"board_entries.last_updated DESC ", :limit=>10})
    categories_hash[:user] = categories_hash[:user] - (categories + categories_hash[:standard] + categories_hash[:system])

    categories_hash
  end

  def diary_date
    format = _("%B %d %Y")
    unless ignore_times
      format = _("%B %d %Y %H:%M")
    end
    date.strftime(format)
  end

  def diary_author
    unless diary?
      "by " + user.name if user
    end
  end

  def visibility
    text = color = ""
    if public?
      text = _("[Open to all]")
      color = "yellow"
    elsif private?
      if diary?
        text = _("[Owner only]")
      else
        text = _("[Group members only]")
      end
      color = "#FFDD75"
    end

    if text == ""
      text = "[#{publication_symbols_value}]"
      color = "#FFCD35"
    end
    return text, color
  end


  LINE_FEED = "\r\n\r\n"
  HR_STRING = LINE_FEED + "----" + LINE_FEED

  # 自動投稿
  def self.create_entry(params)
    params.assert_valid_keys [:title, :message, :tags, :user_symbol, :user_id, :entry_type, :owner_symbol,
                               :publication_type, :publication_symbols, :non_auto, :date, :editor_mode]

    contents = ""
    contents << _("(This entry is generated automatically by the system)") unless params[:non_auto]
    contents << LINE_FEED
    contents << params[:message]

    publication_symbols = []
    publication_symbols = params[:publication_symbols] - [params[:user_symbol]] if params[:publication_type] == 'protected'

    entry = BoardEntry.new(
      :title => params[:title],
      :contents => contents,
      :category => params[:tags],
      :date => params[:date] || Time.now,
      :user_id => params[:user_id],
      :entry_type => params[:entry_type],
      :last_updated => Time.now,
      :editor_mode => params[:editor_mode] || 'hiki',
      :symbol => params[:owner_symbol],
      :publication_type => params[:publication_type],
      :publication_symbols_value => publication_symbols.join(",")
    )
    params[:publication_symbols].each do |symbol|
      entry.entry_publications.build(:symbol => symbol)
    end

    # FIXME エラー処理をする。save! にしてバッチ側で処理すべき
    entry.save
    entry.prepare_send_mail
    return entry
  end

  def self.get_symbol2name_hash entries
    user_symbol_ids = group_symbol_ids = []
    entries.each do |entry|
      case entry.symbol_type
      when "uid"
        user_symbol_ids << entry.symbol_id
      when "gid"
        group_symbol_ids << entry.symbol_id
      end
    end
    symbol2name_hash = {}
    if user_symbol_ids.size > 0
      UserUid.find(:all, :conditions =>["uid IN (?)", user_symbol_ids], :include => :user).each do |user_uid|
        symbol2name_hash[user_uid.user.symbol] = user_uid.user.name
      end
    end
    if group_symbol_ids.size > 0
      Group.active.find(:all, :conditions =>["gid IN (?)", group_symbol_ids]).each do |item|
        symbol2name_hash[item.symbol] = item.name
      end
    end

    symbol2name_hash
  end

  # 記事へのリンクのURLを生成して返す
  def get_url_hash
    url = { :entry_id => id }
    case entry_type
    when "DIARY"
      url[:controller] = "user"
      url[:action] = "blog"
      url[:uid] = symbol_id
    when "GROUP_BBS"
      url[:controller] = "group"
      url[:action] = "bbs"
      url[:gid] = symbol_id
    end
    url
  end

  def symbol_type
    symbol.split(':')[0]
  end

  def symbol_id
    symbol.split(':')[1]
  end

  def symbol_name
    owner = Symbol.get_item_by_symbol(self.symbol)
    owner ? owner.name : ''
  end

  def point
    state.point
  end

  def prepare_send_mail
    if public? # 全公開だとpostしない
      return
    end
    if (entry_publications.size == 1) and (entry_publications.first.symbol == symbol) and diary?
      return # 自分にだけ公開の場合メールはpostしない
    end

    entry_publications.each do |entry_publication|
      next if user.symbol == entry_publication.symbol #書いた人にはメールしない

      to_address = ""
      to_address_name = ""
      to_address_symbol = ""

      symbol = entry_publication.symbol.split(':').last
      case entry_publication.symbol.split(':').first
      when "uid"
        user = User.find_by_uid(symbol)
        if user
          to_address = user.email
          to_address_name = user.name
          to_address_symbol = user.symbol
        end
      when "gid"
        group = Group.active.find_by_gid(symbol, :include => [{ :group_participations => :user }])
        if group
          group.group_participations.each { |participation| to_address << participation.user.email + "," unless participation.waiting }
          to_address = to_address.chop
          to_address_name = group.name
          to_address_symbol = group.symbol
        end
      end

      # 存在しないグループやユーザが指定されている可能性あり
      if to_address.length > 0
        writer = User.find(user_id)

        Mail.create({:from_user_id => writer.uid, :user_entry_no => user_entry_no, :to_address => to_address,
                      :title => title, :to_address_name => to_address_name, :to_address_symbol => to_address_symbol})
      end
    end
  end

  # この記事の作成者かどうか判断する
  def writer?(login_user_id)
    user_id == login_user_id
  end

  # 権限チェック
  # この記事が編集可能かどうかを判断する
  def editable?(login_user_symbols, login_user_id, login_user_symbol, login_user_groups)
    # 所有者がマイユーザ
    return true if login_user_symbol == symbol

    #  マイユーザ/マイグループが公開範囲指定対象で、編集可能
    return true if publicate?(login_user_symbols) && edit?(login_user_symbols)

    # 所有者がマイグループ AND 作成者がマイユーザ
    if login_user_groups.include?(symbol)
      return true if login_user_id == user_id
      #  AND グループ管理者がマイユーザ
      group = Symbol.get_item_by_symbol(symbol)
      return true if publicate?(login_user_symbols) && group.get_owners.any?{|user| user.id == login_user_id}
    end
    return false
  end

  def publicate? login_user_symbols
    entry_publications.any? {|publication| login_user_symbols.include?(publication.symbol) || "sid:allusers" == publication.symbol}
  end

  def edit? login_user_symbols
    entry_editors.any? {|editor| login_user_symbols.include? editor.symbol }
  end

  # アクセスしたことを示す（アクセス履歴）
  def accessed(login_user_id)
    unless writer?(login_user_id)
      state.increment(:access_count)
      state.increment(:today_access_count)
      state.save

      if today_entry= EntryAccess.find(:first, :conditions =>["board_entry_id = ? and updated_on > ? and visitor_id = ?", id, Date.today, login_user_id])
        today_entry.destroy
      end
      if  EntryAccess.count(:conditions => ["board_entry_id = ?", id]) >= 30
        EntryAccess.find(:first, :conditions => ["board_entry_id = ?", id], :order => "updated_on ASC").destroy
      end
      EntryAccess.create(:board_entry_id => id, :visitor_id => login_user_id)
    end
    UserReading.create_or_update(login_user_id, self.id)
  end

  # 話題の信号を送りつける
  def send_trackbacks(login_user_symbols, trackback_target_str)
    message = ""
    new_trackbacks = []
    ids = trackback_target_str.split(/,/).map {|tb| tb.strip }
    if ids.length > 0
      options = { :ids => ids }
      find_params = BoardEntry.make_conditions(login_user_symbols, options)
      entries = BoardEntry.find(:all,
                                :conditions => find_params[:conditions],
                                :include => find_params[:include])
      if entries.length != ids.length
        message = _("(Unknown topic entry found. However, this has been ignored)")
      end

      entries.each do |entry|
        entry_trackbacks = EntryTrackback.find_all_by_board_entry_id_and_tb_entry_id(entry.id, self.id)
        if entry_trackbacks.length > 0
          entry_trackbacks.each {|tb| tb.save }
        else
          new_trackbacks << entry.entry_trackbacks.create({ :tb_entry_id => self.id })
        end
      end
    end
    return message, new_trackbacks
  end

  # 話題にしてくれた記事一覧を返す
  def trackback_entries(login_user_id, login_user_symbols)
    ids =  self.entry_trackbacks.map {|trackback| trackback.tb_entry_id }
    authorized_entries_except_given_user(login_user_id, login_user_symbols, ids)
  end

  # 話題元の記事一覧を返す
  def to_trackback_entries(login_user_id, login_user_symbols)
    ids =  self.to_entry_trackbacks.map {|trackback| trackback.board_entry_id }
    authorized_entries_except_given_user(login_user_id, login_user_symbols, ids)
  end

  # この記事の公開対象ユーザ一覧を返す
  # 戻り値：Userオブジェクトの配列（重複なし）
  def publication_users
    users = []
    entry_publications.each do |pub|
      symbol_type, symbol_id = SkipUtil.split_symbol(pub.symbol)
      case symbol_type
        when "uid"
          users << User.find_by_uid(symbol_id)
        when "gid"
          group = Group.active.find_by_gid(symbol_id, :include => [:group_participations])
          users << group.group_participations.map { |part| part.user } if group
      end
    end
    users.flatten.uniq
  end

  def root_comments
    board_entry_comments.find(:all, :conditions => ["parent_id is NULL"], :order => "created_on")
  end

  def comma_category
    Tag.comma_tags(self.category)
  end

  def cancel_mail
    return unless errors.empty?
    unsent_mails = Mail.find(:all, :conditions =>["from_user_id = ? and user_entry_no = ? and send_flag = false", user.uid, user_entry_no])
    Mail.delete( unsent_mails.collect{ |mail| mail.id }) unless unsent_mails.size == 0
  end

  def self.owner symbol
    symbol_type, symbol_id = Symbol::split_symbol symbol
    if symbol_type == "uid"
      User.find_by_uid(symbol_id)
    elsif symbol_type == "gid"
      Group.active.find_by_gid(symbol_id)
    else
      nil
    end
  end

  def load_owner
    @owner = self.class.owner self.symbol
  end

  def readable?(user)
    user.symbol == self.symbol || (user.group_symbols.include?(self.symbol) || self.publicate?(user.belong_symbols))
  end

  def point_incrementable?(user)
    self.readable?(user) && !self.writer?(user.id)
  end
private
  def generate_next_user_entry_no
    entry = BoardEntry.find(:first,
                            :select => 'max(user_entry_no) max_user_entry_no',
                            :conditions =>['user_id = ?', self.user_id])
    self.user_entry_no = entry.max_user_entry_no.to_i + 1
  end

  # symbol_link([uid:fujiwara>])を参照先のデータに基づいて変換する
  def parse_symbol_link
    # ---- closure ----
    user_proc = proc { |symbol, link_str|
      transfer_symbol_link(symbol, link_str, proc {|symbol_id| (user =  User.find_by_uid(symbol_id)) ? user.name : nil })
    }
    group_proc = proc { |symbol, link_str|
      transfer_symbol_link(symbol, link_str, proc {|symbol_id| (group = Group.active.find_by_gid(symbol_id)) ? group.name : nil })
    }
    page_proc = proc { |symbol, link_str|
      transfer_symbol_link(symbol, link_str, proc {|symbol_id| (entry = BoardEntry.find_by_id(symbol_id)) ? entry.title : nil })
    }
    file_proc = proc {|symbol, link_str|
      transfer_symbol_link(symbol, link_str, proc {|symbol_id|
        (file = ShareFile.find_by_file_name_and_owner_symbol(symbol_id, self.symbol)) ? file.file_name : nil
      })
    }
    # -----------------
    procs = [["uid", user_proc], ["gid", group_proc], ["page", page_proc], ["file", file_proc]]

    split_mark = self.editor_mode == "hiki" ? ">" : "&gt;"
    procs.each { |value| self.contents = BoardEntry.replace_symbol_link(self.contents, value.first, value.last, split_mark) }
  end

  def transfer_symbol_link symbol, link_str, link_str_proc
      if link_str.size > 0
        link_str == symbol ? "[#{symbol}]" : "[#{symbol}>#{link_str}]"
      else
        symbol_type, symbol_id = SkipUtil.split_symbol symbol
        link_str = link_str_proc.call(symbol_id)
        link_str ? "[#{symbol}>#{link_str}]" : _("[Link does not exist...%s>]") % symbol
      end
  end

  # 第一引数textに含まれるsymbol_linkを置換する（[uid:fujiwara>namae]）
  # ２つ目の引数で、対象とするsymbolのtype（uid,gid...）を指定
  # ３つ目の引数で、置換する文字列を生成する関数を指定
  # ４つ目の引数で、symbol_link内の表示文字列指定との区切り文字を指定（'>' or '&gt;'）
  def self.replace_symbol_link text, symbol_type, replace_str_proc, split_mark
    symbol_links = text.scan(/\[#{symbol_type}:[^\]]*?\]/)
    symbol_links.each do |symbol_link|
      symbol_id = symbol_link.strip.split(":", 1).last.chop # fujiwara>namae 第2引数で分割数を指定（>以降の:対応）
      link_str = symbol_link.strip[1..-2]                   # uid:fujiwara>namae
      if symbol_id.scan(split_mark).length > 0 # > によってタイトルが指定されているか
        link_str = symbol_id.match(split_mark).post_match # [uid:fujiwara>namae] の namae
        symbol_id = symbol_id.match(split_mark).pre_match # [uid:fujiwara>namae] の uid:fujiwara
      end
      replace_str = replace_str_proc.call(symbol_link.strip[1..-2].split(split_mark).first, link_str) # [uid:fujiwara>namae]のうちuid:fujwiaraのみを引数に
      text = text.gsub(symbol_link.strip, replace_str)
    end
    return text
  end

  def square_brackets_tags
    self.category = Tag.square_brackets_tags(self.category)
  end

  # 記事が指定されたユーザの記事の場合、指定されたidに一致する記事を全て返す。
  # 記事が指定されたユーザの記事ではない場合、指定されたidに一致する記事のうち、権限のある記事一覧を返す
  def authorized_entries_except_given_user(user_id, user_symbols, ids)
    entries = []
    if ids && ids.length > 0
      find_params = {}
      if user_id == self.user_id
        find_params[:conditions] = ["board_entries.id in (?)", ids]
        find_params[:include] = []
      else
        find_params = BoardEntry.make_conditions(user_symbols, { :ids => ids })
      end
      entries = BoardEntry.find(:all,
                                :conditions => find_params[:conditions],
                                :order => "date DESC",
                                :include => find_params[:include] | [:user])
      entries.each do |entry|
        entry.load_owner
      end
    end
    entries
  end
end
