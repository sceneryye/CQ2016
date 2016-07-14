class EventsController < ApplicationController
	# layout 'event'
	layout 'magazine'

	def show
		@event =  Event.find(params[:id])
	end
end
