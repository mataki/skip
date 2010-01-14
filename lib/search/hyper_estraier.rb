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

require "estraierpure"

class Search
  class HyperEstraier
    ACCESS_DENIED_ERROR_MSG = "Access denied by search node. Please contact system owner."
    include EstraierPure
    attr_reader :offset, :per_page, :error, :result_hash

    def initialize params
      @result_hash = {
        :header => { :count => -1, :start_count => 0, :end_count => 0, :prev => "", :next => "", :per_page => 10 },
        :elements => []
      }
      @per_page = (params[:per_page] || 10).to_i
      @offset = (params[:offset] || 0).to_i

      node = self.class.get_node
      cond = self.class.get_condition(params[:query], params[:target_aid], params[:target_contents])
      if nres = node.search(cond, 1)
        @result_hash[:header] = self.class.get_result_hash_header(nres.hint('HIT').to_i, @offset, @per_page)
        @result_hash[:elements] = self.class.get_result_hash_elements(nres, @offset, @result_hash[:header][:end_count])
      else
        # ノードにアクセスできない場合のみ nres は nil
        ActiveRecord::Base.logger.error "[HyperEstraier Error] Connection not found to #{SkipEmbedded::InitialSettings["estraier_url"]}"
        @error = ACCESS_DENIED_ERROR_MSG
      end
    end

    def self.get_condition(query, target_aid = nil, target_contents = nil)
      cond = Condition.new
      cond.set_options Condition::SIMPLE
      cond.set_phrase(query) unless query.blank?
      if target_aid && SkipEmbedded::InitialSettings['search_apps'][target_aid] && !SkipEmbedded::InitialSettings['search_apps'][target_aid]['cache'].blank?
        target_url = SkipEmbedded::InitialSettings['search_apps'][target_aid]['cache'].dup
        target_url << "/#{target_contents}" if target_contents
        cond.add_attr("@uri STRBW #{target_url}")
      end
      cond
    end

    def self.get_node(node_url = SkipEmbedded::InitialSettings['estraier_url'])
      node = Node.new
      node.set_url(node_url)
      node
    end

    def self.get_result_hash_header(count, offset, per_page)
      {
        :count => count,
        :start_count => offset + 1,
        :end_count => offset+per_page > count ? count : offset+per_page,
        :prev => offset > 0 ? "true" : "",
        :next => offset+per_page < count ? "true" : "",
        :per_page => per_page
      }
    end

    def self.get_result_hash_elements(nres, offset, end_count)
      (offset...end_count).map do |i|
        rdoc = nres.get_doc(i)
        Search.get_metadata(ERB::Util.html_escape(rdoc.snippet), URI.decode(rdoc.attr('@uri')), rdoc.attr('@title')) unless rdoc.nil?
      end.compact
    end
  end
end
