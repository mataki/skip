class RankingController < ApplicationController
  layout false
  def update
    new_ranking = Ranking.new params[:ranking]
    exisiting_ranking = Ranking.find_by_url_and_extracted_on_and_contents_type(new_ranking.url, new_ranking.extracted_on, new_ranking.contents_type)
    if exisiting_ranking.empty?
      if new_ranking.save 
        head :created 
      else
        head :bad_request
      end
    else
      if exisiting_ranking.first.add_amount(new_ranking.amount)
        head :ok
      else
        head :bad_request
      end
    end
  end

  # GET /rankings/:content_type/:year/:month
  def index
    if params[:content_type].blank?
      return head :bad_request
    end

    unless params[:year]
      @rankings = Ranking.all(params[:content_type])
    else
      if params[:month]
        @rankings = Ranking.monthly(params[:content_type], params[:year], params[:month])
      end
    end
  end

  def all
    render :layout => 'layout'
  end

  def monthly
  end

  def history
  end
end
