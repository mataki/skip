# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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
  NO_QUERY_ERROR_MSG = "Please input search query."

  attr_reader :invisible_count, :result, :error

  def initialize params, publication_symbols
    unless params[:query] && !SkipUtil.jstrip(params[:query]).empty?
      @error = NO_QUERY_ERROR_MSG
    else
      est_result = HyperEstraier.new(params)
      if error_message = est_result.error
        @error = error_message
      else
        @result = est_result.result_hash
        new_result = self.class.remove_invisible_element(@result[:elements], publication_symbols)
        @invisible_count = @result[:elements].size - new_result.size
        @result[:elements] = new_result
      end
    end
  end

  def self.remove_invisible_element elements, publication_symbols
    elements.map do |line_hash|
      line_hash unless ((line_hash[:publication_symbols]||"").split(',') & publication_symbols).blank?
    end.compact
  end

  def self.get_metadata contents, uri_text, title
    line_hash = { :publication_symbols => 'sid:allusers', :contents => contents, :link_url => uri_text, :title => title }
    SkipEmbedded::InitialSettings['search_apps'].each do |key,value|
      if uri_text.include?(value['cache'])
        if value['meta']
          line_hash.merge!(get_metadata_from_file(uri_text, value['cache'], value['meta']))
        else
          line_hash.merge!( :contents_type => key.to_s, :icon_type => value['icon_type'] )
        end
      end
    end
    line_hash
  end

  def self.get_metadata_from_file(uri_text, cache, meta)
    file_path = uri_text.gsub(cache, meta)
    if File.file? file_path
      YAML::load(File.open(file_path)).with_indifferent_access.symbolize_keys
    else
      ActiveRecord::Base.logger.error "[FULL TEXT SEARCH] cannot find meta file #{file_path} to #{cache}"
      { :publication_symbols => 'sid:noneuser' }
    end
  end
end
