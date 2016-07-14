class Admin::EmailsController < Admin::BaseController
	def index
		@emails = Email.paginate(:page=>params[:page] || 1,:per_page=>20)
	end

	def new
		@email = Email.new
	end

	def create
		@email = Email.new(params[:email])
		@email.save
		redirect_to admin_emails_url
	end

	def destroy
		@email = Email.find(params[:id])
		@email.destroy
		redirect_to admin_emails_url
	end

	def send_all
		@emails = Email.all
		@emails.each do |email|
			UserMailer.user_email(email.addr,"CQ").deliver
			sleep 0.1
		end
		redirect_to admin_emails_url
	end
end
