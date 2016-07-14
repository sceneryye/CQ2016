class Admin::FootersController < Admin::BaseController

	def index
		@footers =  Footer.paginate(:per_page=>20,:page=>params[:page]).order("updated_at desc")
	end

	def new
		@footer  = Footer.new
		@action_url =  admin_footers_path
		@method = :post
	end

	def show
		@footer  = Footer.find(params[:id])
	end

	def edit
		@footer  = Footer.find(params[:id])
		@action_url =  admin_footer_path(@footer)
		@method = :put
	end

	def create
		@footer  = Footer.new params[:footer]
		if @footer.save
			redirect_to admin_footers_url
		else
			render :new
		end
	end

	def update
		@footer  = Footer.find(params[:id])
		if @footer.update_attributes(params[:footer])
			redirect_to admin_footers_url
		else
			render :edit
		end
	end

	def destroy
		@footer  = Footer.find(params[:id])
		@footer.destroy
		redirect_to admin_footers_url
	end
end
