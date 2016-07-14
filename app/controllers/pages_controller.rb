class PagesController < ApplicationController

	layout 'application'

	def show
		@page = Page.includes(:meta_seo).find(params[:id])

        render :layout=> @page.layout.present? ? @page.layout : nil

	end



end
