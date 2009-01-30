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

require "estraierpure"

class HyperEstraier < Search
  include EstraierPure

  def self.search params,result_hash
    per_page = (params[:per_page] || 10).to_i
    offset = (params[:offset] || 0).to_i

    begin
      node = Node::new
      node.set_url(INITIAL_SETTINGS['estraier_url'])
      cond = Condition::new
      cond.set_options Condition::SIMPLE
      cond.set_phrase(params[:query])
      if params[:target_aid] && params[:target_aid] != 'all' && !INITIAL_SETTINGS['search_apps'][params[:target_aid]]['cache'].empty?
        target_url = "http://#{INITIAL_SETTINGS['search_apps'][params[:target_aid]]['cache']}"
        target_url << "/#{params[:target_contents]}" if params[:target_contents]
        cond.add_attr("@uri STRBW #{target_url}")
      end
      nres = node.search(cond,1)
      if nres
        count = nres.hint('HIT').to_i
        result_hash[:header][:count] = count
        result_hash[:header][:start_count] = offset+1
        result_hash[:header][:end_count] = offset+per_page > count ? count : offset+per_page
        result_hash[:header][:prev] = offset > 0 ? "true" : ""
        result_hash[:header][:next] = offset+per_page < count ? "true" : ""
        result_hash[:header][:per_page] = per_page
        result_array = []

        for i in offset...(nres.doc_num < offset+per_page ? nres.doc_num : offset+per_page)
          rdoc = nres.get_doc(i)
          result_array << (get_metadata ERB::Util.html_escape(rdoc.snippet), URI.decode(rdoc.attr('@uri')), rdoc.attr('@title'))
        end # rdoc
        result_hash[:elements] = result_array
      else
        return { :error => "検索エンジンにアクセスできません。管理者に連絡してください。" }
      end # if nres
    rescue Exception => e
      ActiveRecord::Base.logger.error e
      e.backtrace.each { |message| ActiveRecord::Base.logger.error message }
      return { :error => "現在全文検索エンジンに問題が発生しており、検索できません。" }
    end
    return result_hash
  end

end
