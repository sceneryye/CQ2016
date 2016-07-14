class Admin::TagExtsController < Admin::BaseController
	
	def index
		key = params[:search][:key] if params[:search] && params[:search][:key]
		@tags = TagName.where('tag_name rlike ?','z[0-9]{4}').order("tag_id desc")
		unless key.blank?
			@tags = @tags.where("tag_name like ?","%#{key}%")
		end

		@tags = @tags.paginate(:page=>params[:page],:per_page=>10)
	end

	def edit
		@tag = TagName.find(params[:id])
		@tag_ext = @tag.tag_ext || TagExt.new(:tag_name=>@tag.tag_name,:tag_id=>@tag.tag_id)
	end

	def update
		@tag_ext = TagExt.find_by_tag_id(params[:id])
		 if @tag_ext
			@tag_ext.update_attributes(params[:tag_ext])
		else
			TagExt.create params[:tag_ext]
		end

		redirect_to admin_tag_exts_url
	end
end
