class Store::SuppliersController < ApplicationController
	# layout 'magazine'
      layout 'standard'
  	# before_filter :require_top_cats
  	
  	def show
        @supplier = Supplier.find(params[:id])   
    end
end
