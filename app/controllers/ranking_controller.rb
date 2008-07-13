class RankingController < ApplicationController
  def update
    new_ranking = Ranking.new params[:ranking]
    exisiting_ranking = Ranking.find_by_url_and_extracted_on_and_contents_type_id(new_ranking.url, new_ranking.extracted_on, new_ranking.contents_type_id)
    if exisiting_ranking.empty?
      if new_ranking.save 
        head :created 
      else
        head :bad_request
      end
    else
      if exisiting_ranking.first.add_amaount(new_ranking.amaount)
        head :ok
      else
        head :bad_request
      end
    end
  end
end
