#encoding:utf-8
class UsersController < ApplicationController
  skip_before_filter :find_cart!
  skip_before_filter :find_path_seo
  
  layout "application"

  def new
    return_url=params[:return_url]
    @from = params[:from]
    if @user
      @account = Account.find(@user.member_id)
      @action_url = "/users/#{@account.account_id}?return_url=#{return_url}"#users_path(@account)
      @method = :put
    else
  	  @account = Account.new
      @action_url = "/users/?return_url=#{return_url}"#users_path
      @method = :post
    end
  end

  def create
    supplier_id = 1
  	now  = Time.now
    #params[:user].merge!(:login_name=>params[:user][:email])
	  @account = Account.new(user_params) do |ac|
  		ac.account_type ="member"
  		ac.createtime = now.to_i
  		ac.user.member_lv_id = 1
  		ac.user.cur = "CNY"
  		ac.user.reg_ip = request.remote_ip
  		ac.user.regtime = now.to_i
      ac.supplier_id = supplier_id
  	end

	  if @account.save!
      sign_in(@account)
      @return_url=params[:return_url]
     # render "create"
      respond_to do |format|
        format.js
      end
    else
      render "error"     
    end
  end

  def update    
    @account = Account.find(@user.member_id)
    if @account.update_attributes(params[:user])
      sign_in(@account)
      @return_url=params[:return_url]
      if @return_url.empty?
        redirect="/profile"
      else
        redirect = @return_url
      end
      return redirect_to redirect
    else
      render "error"     
    end
  end

  def search
      @title = "找回密码"
      @by = params[:user][:by]
      value = params[:user][:value]
      col =  case @by
          when 'mobile' then '手机号码'
          when 'email' then '邮箱'
          when 'login_name' then '会员名'
          else '会员名'
      end
      if value.present?
          @user = User.joins(:account).where("#{@by} = ?",value).first
          if @user
            render "find_by_#{@by}"
          else
            redirect_to forgot_password_users_url(:by=>@by), :notice=> "您输入的#{col}不存在"
          end
      else
          redirect_to forgot_password_users_url(:by=>@by), :notice=> "请输入#{col}"
      end
  end

  def forgot_password
    @title = "找回密码"
    render :layout=>"simple"
  end

  def send_reset_password_instruction
    @title = "找回密码"
    member_id = params[:user][:member_id]
    @by = params[:user][:by]
    @user = User.where(:member_id=>member_id).first
    @user.send_reset_password_instruction(@by)

    respond_to do |format|
      format.js { render :nothing=>true }
      format.html
    end

  end

  def reset_password
    @title = "重设密码"
    by = params[:by] || "email"
    
    @user = User.where(:member_id=>params[:u],:reset_password_token=>params[:token]).first

    respond_to do |format|
      if @user && !@user.reset_password_token_expired?
        format.js { render :js=>"window.location.href='#{reset_password_users_url(params)}'" }
        format.html
      else
        format.js { render "sms_code_error" }
        format.html { redirect_to forgot_password_users_url, :notice=>"重设密码的链接错误" }
      end
    end

  end

  def change_password
    @title = "修改密码成功"
    @account = Account.where(:account_id=>params[:account][:account_id]).first
    if @account.change_password(params[:account][:login_password],
                                                           params[:account][:login_password_confirmation])
      @account.user.clear_reset_password_token
    else
      @user = @account.user
      render :reset_password
    end
  end

  private

  def user_params
    params.require(:user).permit(:auth_ext_id, :login_name, :login_password,:account_type, :login_password_confirmation, :email, :mobile,:real_name,:follow_imodec,:license,:current_password)
  end

end
