class Admin::SpecificationsController < Admin::BaseController

	def index
		@specs =  Spec.paginate(:per_page=>20,:page=>params[:page]).order("p_order desc")
	end

	def new
		@spec  = Spec.new

		@action_url =  admin_specifications_path
		@method = :post
	end

	def show
		@spec  = Spec.find(params[:id])
	end

	def edit
		@spec  = Spec.includes(:spec_values).find(params[:id])

         @spec.save
		@action_url =  admin_specification_path(@spec)
		@method = :put
	end

	def create
		@spec  = Spec.new(spec_params)
		if @spec.save
			redirect_to admin_specifications_url
		else
			render :new
		end
	end

	def update
		@spec  = Spec.find(params[:id])
		if @spec.update_attributes(spec_params)
			redirect_to admin_specifications_url
		else
			render :edit
		end
	end

	def destroy
		@spec  = Spec.find(params[:id])
		@spec.destroy
		redirect_to admin_specifications_url
	end

	private
	def spec_params
		params.require(:spec).permit(:spec_name,:spec_memo,:alias,:spec_type,:spec_show_type,:spec_values_attributes)
	end
end
