#encoding:utf-8
class Memberships::MemberAddrsController < ApplicationController
  before_filter :find_user

  layout "application"

  def new
    @addr = MemberAddr.new
  end

  def index
    
    @addrs = @user.member_addrs.paginate(:per_page=>10,:page=>params[:page])
    add_breadcrumb("收货地址")
    @newurl = "new"

  end


  def edit
    @addr = MemberAddr.find(params[:id])
    @method = :put
    @action_url = member_addr_path(@addr)
  end

  def create
    @addr = MemberAddr.new addr_params.merge!(:member_id=>@user.member_id)

    return_url= params[:return_url]

   if @addr.save
      if return_url
        redirect_to return_url
      else
        respond_to do |format|
          format.js
          format.html { redirect_to member_addrs_url }
        end
      end
    else
      render "error.js" #, status: :unprocessable_entity
    end

  end

  def new_memberaddr_add
    @addr=MemberAddr.new
  end

  def update
    @addr = MemberAddr.find(params[:id])
    if @addr.update_attributes(addr_params)
      respond_to do |format|
        format.js
        format.html { redirect_to "/member_addrs?platform=#{params[:platform]}" }
      end
    else
      render 'error.js' #, status: :unprocessable_entity
    end
  end

  def destroy

    @addr = MemberAddr.find(params[:id])
    @addr.destroy
    if params[:platform]=="mobile"
      @supplier=Supplier.find(params[:supplier_id])
      redirect_to "/member_addrs/mobile?platform=mobile&supplier_id=#{@supplier.id}"
     else

      redirect_to "/member_addrs?platform=#{params[:platform]}"
    end
   
  end

   private 
    def addr_params
      params.require(:addr).permit(:province, :city, :district, :addr, :zip, :name, :mobile, :tel, :def_addr, :member_id ,:addr_type)
    end
  
end