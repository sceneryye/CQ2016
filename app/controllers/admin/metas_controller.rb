class Admin::MetasController < Admin::BaseController
	def index
		@metas = MetaSeo.path_metas.paginate(:per_page=>20,:page=>params[:page])
	end

	def new
		@meta = MetaSeo.new(:metable_type=>"path")
		@action_url = admin_metas_path
		@method = :post
	end

	def edit
		@meta = MetaSeo.find(params[:id])
		@action_url = admin_meta_path(@meta)
		@method = :put
	end


	def create
		@meta =  MetaSeo.new params[:meta]
		if @meta.save
			redirect_to admin_metas_url
		else
			render :new
		end
	end

	def update
		unless params[:meta].key?(:params)
			params[:meta].merge! :params=>[]
		end
		@meta =  MetaSeo.find params[:id]

		if @meta.update_attributes(params[:meta])
			redirect_to admin_metas_url
		else
			render :edit
		end
	end

	def destroy
		@meta =  MetaSeo.find params[:id]
		@meta.destroy
		redirect_to admin_metas_url
	end
end
