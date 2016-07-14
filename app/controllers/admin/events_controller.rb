class Admin::EventsController < Admin::BaseController
	def index
		@events  = Event.paginate(:page => params[:page], :per_page => 20).order("created_at desc")
	end

	def new
		@create_or_update_path = admin_events_path
		@event = Event.new
	end

	def show
		@event = Event.find(params[:id])
		# @applicants = @event.applicants
	end

	def applicants
		@event = Event.find(params[:id])
		@applicants = @event.applicants.paginate(:page => params[:page], :per_page => 20).order("created_at desc")
	end
	
	def edit

		@event = Event.find(params[:id])
		@create_or_update_path = admin_event_path(@event)
	end

	def create
		@event = Event.new params[:imodec_event]
		

		if @event.save
			redirect_to edit_admin_event_url(@event)
		else
			render "new"
		end

	end

	def update
		@event = Event.find(params[:id])
		if @event.update_attributes(params[:imodec_event])
			redirect_to edit_admin_event_url(@event)
		else
			render action: "edit"
		end
	end

	def destroy
		@event = Event.find(params[:id])
    		@event.destroy

	      respond_to do |format|
	        format.html { redirect_to admin_events_url }
	        format.json { head :no_content }
	      end
	end
end
