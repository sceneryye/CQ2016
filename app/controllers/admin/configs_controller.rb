class Admin::ConfigsController < Admin::BaseController
	def index
		@configs =  Config.all
	end

	def new
		@config  =  Config.new
	end

	def edit
		@config  =  Config.find(params[:id])
	end

	def create
		@config = Config.new(params[:config])
		if @config.save
			redirect_to admin_configs_url
		else
			render :new
		end
		
	end

	def update
		@config = Config.find(params[:id])
		if @config.update_attributes(params[:config])
			redirect_to admin_configs_url
		else
			render :edit
		end
		
	end
end
