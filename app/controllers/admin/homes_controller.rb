class Admin::HomesController < Admin::BaseController
  def index
  	@homes = Home.paginate(:page=>params[:page],:per_page=>10).order("created_at desc")
  end

  def new
  	@home  = Home.new
  	@action_url = admin_homes_path
       @method = :post
  end

  def edit
  	@home  = Home.find(params[:id])
  	@action_url = admin_home_path(@home)
      @method = :put
  end

  def create
    return rdender text: home_params
  	@home  = Home.new(home_params)
  	if @home.save
  		redirect_to admin_homes_url
  	else
  		@action_url = admin_homes_path
  		render "new"
  	end
  end

  def update
  	@home  = Home.find(params[:id])
    return render text: home_params
  	if @home.update_attributes(home_params)
  		redirect_to admin_homes_url
  	else
  		@action_url = admin_home_path(@home)
  		render "edit"

  	end
  end

  def destroy
  	@home  = Home.find(params[:id])
  	@home.destroy
  	redirect_to admin_homes_path
  end

  private
  def home_params
    params.require(:home).permit(:sliders,:body,:keywords,:hots,:suits,:brands)
  end


end
