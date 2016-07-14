#encoding:utf-8
class Admin::RebatesController < Admin::BaseController
	before_filter :require_permission!


	def show

	end
	  
	def index
	    @status = params[:status].to_i
		if @status.blank?
			@status = 0		
		end
		if @status == 0
			@no='disabled'
		else
			@yes = 'disabled'
		end	

		@rebates =   Rebate.where(status: @status).order('id desc')	

	    @rebates_total = @rebates.count
	    @rebates = @rebates.paginate(:page=>params[:page],:per_page=>20)	

	end

end
