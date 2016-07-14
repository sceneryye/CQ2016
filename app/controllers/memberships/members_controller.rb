#encoding:utf-8
require 'axlsx'

require 'digest'
require 'openssl'
require "base64"
require 'open-uri'
require 'typhoeus'

class Memberships::MembersController < ApplicationController
 
	
	before_filter :authorize_user!
	# layout 'standard'
	layout "application"

	before_filter do
		clear_breadcrumbs
		add_breadcrumb("我的昌麒",:member_path)
	end

  def new
   
  end


  def update
    member_params = user_params
    addr_params = user_params
   

    if @user.update_attributes(member_params.merge!(:apply_time=>Time.now))    

      addr_params.merge!(:member_id=>@user.member_id,:def_addr=>1).delete(:id_card_number)  
      @addr = MemberAddr.create(addr_params)

      redirect_to new_card_path
    else
      render "new"
    end
  end

  def advance
    @deposit = 0

    @deposit = @user.member_lv.deposit if @user.member_lv
  

    @advances = @user.member_advances.paginate(:page=>params[:page],:per_page=>10)
    add_breadcrumb("我的会员卡提现")
  end
  
  def favorites
    @favorites = @user.favorites.includes(:good).paginate(:page=>params[:page],:per_page=>10).order("create_time desc")
    add_breadcrumb("我的收藏")
  end

	def show
		@orders = @user.orders.limit(5)
		@unpay_count = @user.orders.where(:pay_status=>'0',:status=>'active').size
    @paid_count = @user.orders.where(:pay_status=>'1',:status=>'active').size
    @history_count = @user.orders.where("pay_status='1' and (ship_status = '1' or status <> 'active')").size
		add_breadcrumb("我的昌麒")
	end

	def orders
    pay_status = params[:pay_status]
    status = params[:status]
    if  pay_status.present?
      condition = "pay_status='#{pay_status}'"
      if pay_status=='1'
        @paid ='disabled'
      else
        @unpaid='disabled'
      end

    else
      condition = "pay_status='1' and (ship_status = '1' or status <> 'active')"
      @history ='disabled'
    end
		@orders = @user.orders.where(condition).order('order_id DESC').paginate(:page=>params[:page],:per_page=>10)

		add_breadcrumb("我的订单")
     @coupon_id = params[:coupon_id]
    if @coupon_id
      render :layout=>'coupons'
    end
	end

	def coupons
    @coupon_id = params[:coupon_id]
    if @coupon_id
  		@user_coupons = @user.user_coupons.where(:coupon_id=>@coupon_id).paginate(:page=>params[:page],:per_page=>10)
    else
      return render :text=>'卡券类型不正确'
    end
		add_breadcrumb("我的卡券")
    render :layout=>'coupons'
  end


  private
   def user_params
      params.require(:user).permit(:name,:card_num,:area,:mobile,:addr,:sex,:id_card_number,:province, :city, :district,)
    end

	
end
