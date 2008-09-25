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

class Search
  class SearchError < StandardError
  end

  def initialize params,publication_symbols
    @result = {
      :header => { :count => -1, :start_count => 0, :end_count => 0, :prev => "", :next => "", :per_page => 10 },
      :elements => []
    }
    if params[:query] && !SkipUtil.jstrip(params[:query]).empty?
      @result = HyperEstraier.search params,@result
    end

    if error_message = @result[:error]
      raise SearchError, error_message
    end

    new_result = []
    @result[:elements].each do |line_hash|
      line_hash[:publication_symbols] = 'sid:allusers' if line_hash[:publication_symbols].blank?
      both_arr = line_hash[:publication_symbols].split(',') & publication_symbols
      new_result << line_hash if both_arr.size > 0
    end

    @invisible_count = @result[:elements].size - new_result.size
    @result[:elements] = new_result
  end

  attr_reader :invisible_count, :result

  def self.get_metadata contents,uri_text,title
    line_hash = { }
    line_hash[:contents] = contents

    INITIAL_SETTINGS['search_apps'].each do |key,value|
      if value['meta'] && uri_text.include?("/#{value['cache']}/") #メタファイルを設定している場合
        file_path = uri_text.gsub("http://#{value['cache']}", value['meta'])
        if File.file? file_path
          YAML::load(File.open(file_path)).each { |key,value| line_hash[key.to_sym] = value }
          line_hash[:title] = URI.decode(URI.decode(line_hash[:title]))
        else
          line_hash[:publication_symbols] = 'sid:noneuser'
        end
      elsif uri_text.include?("/#{value['cache']}") #iconを指定する
        line_hash[:contents_type] = key.to_s
        line_hash[:icon_type] = value['icon_type'] if value['icon_type']
      end
    end #INITIAL_SETTINGS['search_apps']
    # メタファイルを設定していない場合
    line_hash[:publication_symbols] ||= 'sid:allusers'
    line_hash[:title] ||= title || uri_text
    line_hash[:link_url] ||= uri_text
    return line_hash
  end
end
