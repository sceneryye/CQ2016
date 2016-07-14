class Admin::PagesController < Admin::BaseController
  before_filter :require_permission!
  def index
    @pages = Page.paginate(:page => params[:page], :per_page => 20).order("created_at DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pages }
    end
  end

  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @page }
    end
  end

  def edit
    @page = Page.find(params[:id])
  end

  def create
    @page = Page.new(page_params)
    
    respond_to do |format|
      if @page.save
        format.html { redirect_to admin_pages_path, notice: 'Page was successfully created.' }
        format.json { render json: @page, status: :created, location: @page }
      else
        format.html { render action: "new" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @page = Page.find(params[:id])

    respond_to do |format|
      if @page.update_attributes(page_params)
        format.html { redirect_to admin_pages_url, notice: 'Page was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @page = Page.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to admin_pages_url }
      format.json { head :no_content }
      format.js
    end
  end

  def set_position
    @page = ::Page.find(params[:id])
    @page_prev = ::Page.find_by_position_id(params[:position_id])
    if @page_prev
      @page_prev.position_id = nil
    end
    
    respond_to do |format|
      if @page.update_attribute("position_id", params[:position_id].to_i)
        if @page_prev
          @page_prev.save!
          format.json { render json: {page_prev_id: @page_prev.id} }
        else
          format.json { render json: {page_prev_id: 0} }
        end
      else
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end

    # respond_to do |format|
    #   # format.json { head :ok }
    #   format.json { render json: @page.errors }
    # end
  end

  private
  def page_params
      params.require(:page).permit(:title,:slug,:layout,:category,:body,:keywords,:description,meta_seo_attributes:[])
  end
end
