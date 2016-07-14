class Admin::StaticPagesController < Admin::BaseController

	def index

		@pages =  Page.paginate(:per_page=>20,:page=>params[:page]).order("updated_at desc")

  end

	def new
		@page  = Page.new
		@action_url =  admin_static_pages_path
		@method = :post
	end

	def show
		@page  = Page.find(params[:id])
    @recommend_user = session[:recommend_user]

    if @recommend_user==nil &&  params[:wechatuser]
      @recommend_user = params[:wechatuser]
    end
    if @recommend_user
      member_id =-1
      if signed_in?
        member_id = @user.member_id
      end
      now  = Time.now.to_i
      RecommendLog.new do |rl|
        rl.wechat_id = @recommend_user
        rl.goods_id = @good.goods_id
        rl.member_id = member_id
        rl.terminal_info = request.env['HTTP_USER_AGENT']
        #   rl.remote_ip = request.remote_ip
        rl.access_time = now
      end.save
      session[:recommend_user]=@recommend_user
      session[:recommend_time] =now
    end

  end

	def edit
		@page  = Page.find(params[:id])
		@action_url =  admin_static_page_path(@page)
		@method = :put
	end

	def create
		@page  = Page.new page_params
		if @page.save
			redirect_to admin_static_pages_url
		else
			render :new
		end
	end

	def update
		@page  = Page.find(params[:id])
		if @page.update_attributes(page_params)
			redirect_to admin_static_pages_url
		else
			render :edit
		end
	end

	def destroy
		@page  = Page.find(params[:id])
		@page.destroy
		redirect_to admin_static_pages_url
	end
	private
	def page_params
	    params.require(:page).permit(:title,:slug,:layout,:category,:body,:keywords,:description,meta_seo_attributes:[])
	end
end
