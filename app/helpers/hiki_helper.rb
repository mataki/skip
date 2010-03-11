module HikiHelper
  # 第一引数textに含まれるsymbol_linkを置換する（[uid:fujiwara>namae]）
  # ２つ目の引数で、対象とするsymbolのtype（uid,gid...）を指定
  # ３つ目の引数で、置換する文字列を生成する関数を指定
  # ４つ目の引数で、symbol_link内の表示文字列指定との区切り文字を指定（'>' or '&gt;'）
  def replace_symbol_link text, symbol_type, replace_str_proc, split_mark
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

  def parse_permalink text, owner = nil
    return '' unless text

    user_proc = proc { |cymbol, link_str|
      link_url = polymorphic_url([current_tenant, :user], :id => cymbol.split(':').last)
      link_to link_str, link_url
    }

    group_proc = proc { |cymbol, link_str|
      link_url = polymorphic_url([current_tenant, :group], :id => cymbol.split(':').last)
      link_to link_str, link_url
    }

    entry_proc = proc { |cymbol, link_str|
      link_url = polymorphic_url([current_tenant, :board_entry], :id => cymbol.split(':').last)
      link_to link_str, link_url
    }

    file_proc = proc { |cymbol, link_str|
      file_name = cymbol.split(':').last
      file_name.gsub!(/\r\n|\r|\n/, '')
      share_file = ShareFile.accessible(current_user).find_by_file_name(file_name)
      if share_file
        link_url = polymorphic_url([current_tenant, owner, share_file], :authenticity_token => form_authenticity_token)
        link_to link_str, link_url
      else
        _("[Link does not exist...%s>]") % cymbol
      end
    }

    procs = [["uid", user_proc], ["gid", group_proc], ["page", entry_proc]]
    procs << ["file",file_proc] if owner

    split_mark =  "&gt;"
    procs.each { |value| text = replace_symbol_link(text, value.first, value.last, split_mark) }
    text
  end

  def parse_hiki_embed_syntax view_str, proc
    regex_type = /\{\{.+?\}\}/ # {{***}}とマッチする正規表現
    width = 0
    height = 0
    image_name = ""

    while image_tag = view_str.match(regex_type)
      image_size = [0,0] # デフォルトサイズ

      # カンマ２つでサイズが指定してある場合
      if image_tag.to_s.scan(",").size == 2
        params = image_tag.to_s[2..-3].split(",")
        image_name = params[0]
        width, height = [params[1].to_i, params[2].to_i]
      else
        image_name = image_tag.to_s[2..-3]
      end
      image_name.strip!

      #イメージのURLを生成できるブロックを呼び出す
      image_url = proc.call(image_name)
      image_link =
        if File.extname(image_name).sub(/\A\./,'').downcase == "flv"
          flv_tag image_url
        elsif File.extname(image_name).sub(/\A\./,'').downcase == "swf"
          width = 240 if width == 0
          height = (width * 0.75) if height == 0
          swf_tag image_url, :width => width, :height => height
        else
          img_options = {}
          img_options[:width] = width if width > 0
          img_options[:height] = height if height > 0
          link_to image_tag(image_url, img_options), image_url, :class => 'zoomable'
        end

      view_str = view_str.sub(regex_type, image_link)
    end
    return view_str
  end

  def hiki_parse text, owner = nil
    text = HikiDoc.new((text || ''), Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
    parse_permalink(text, owner)
  end
end
