require 'pp'
class Magazine::PagesController < Magazine::BaseController
  layout false

  skip_before_filter :authorize_user!

  def show
    @page = Page.find(params[:id])
  end

  def index
    @topic = Topic.find(params[:topic_id])
    @pages = Page.where(:topic_id => @topic.id)
  end


end
