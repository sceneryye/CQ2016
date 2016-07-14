class Admin::OfflineCouponsController < Admin::BaseController
	
	def index
		@coupons = OfflineCoupon.paginate(:per_page=>10,:page=>params[:page]).order("created_at asc")
	end

	def new
		@coupon  = OfflineCoupon.new
		@action_url = admin_offline_coupons_path
		@method = :post
	end

	def show
		@coupon  = OfflineCoupon.find(params[:id])
	end

	def edit
		@coupon  = OfflineCoupon.find(params[:id])
		@action_url = admin_offline_coupon_path(@coupon)
		@method = :put
	end

	def create
		@coupon  = OfflineCoupon.new(params[:coupon])

		if @coupon.save
			redirect_to admin_offline_coupons_url
		else
			render :new
		end
	end

	def update
		@coupon  = OfflineCoupon.find(params[:id])
		if @coupon.update_attributes(params[:coupon])
			redirect_to admin_offline_coupons_url
		else
			render :edit
		end
	end

	def destroy
		@coupon  = OfflineCoupon.find(params[:id])
		@coupon.destroy

		redirect_to admin_offline_coupons_url
	end

	def downloads
		@coupon  = OfflineCoupon.find(params[:id])
		@downloads = @coupon.coupon_downloads.paginate(:page=>params[:page],:per_page=>20).order("downloaded_at desc")
	end
end
