class Admin::LabelsController < Admin::BaseController
	layout 'dialog'

	def index
		@labels = Label.all
	end

	def edit
		@label = Label.find(params[:id])
	end

	def update
		@label = Label.find(params[:id])
		if @label.update_attributes(params[:label])
			redirect_to  admin_labels_url
		else
			render "edit"
		end
	end

	def create
		@label = Label.new(params[:label])
		@label.save
		redirect_to admin_labels_url
	end

	def destroy
		@label = Label.find(params[:id])
		@label.destroy
		redirect_to admin_labels_url
	end
end
