#encoding:utf-8
class SessionsController < ApplicationController
  require 'rest-client'

  skip_before_filter :authorize_user!
  layout 'application'

  def new

  end

  def auto_login
    config.site = "https://open.weixin.qq.com/"
    config.api_site = "https://open.weixin.qq.com/"
    config.client_id = "wxf9945fddc9b67aaa"
    config.client_secret =  "b2248ee62274de8680d26e6e355c350a"
    config.redirect_uri = "http://www.cq2016.cc/auth/weixin/callback"
    config.ssl = { :ca_path=>"/usr/lib/ssl/certs" }
    config.authorize_uri = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    config.access_token_uri = 'https://api.weixin.qq.com/sns/oauth2/access_token'
    config.path_prefix = '2/'
    # config.uid = 'gh_64cd6ce595eb'
    # return render text: config.site

    supplier_id = 1

    #redirect_uri = "http://www.cq2016.cc/auth/weixin/callback?supplier_id=#{@supplier.id}"
    #redirect_uri= URI::escape(redirect_uri)
    redirect_uri="http%3a%2f%2fwww.cq2016.cc/%2fauth%2fweixin%2f#{supplier_id}%2fcallback"
    @oauth2_url = "#{config.authorize_uri}?appid=#{config.client_id}&redirect_uri=#{redirect_uri}&response_type=code&scope=snsapi_userinfo&state=STATE#wechat_redirect"

    return_url  = params[:return_url]
    session[:return_url] =  return_url
    redirect_to  @oauth2_url

  end

 
  def create
     
    @return_url=params[:return_url]

    @platform = params[:platform]

    if @platform == 'vshop'
      @account = Account.admin_authenticate(params[:session][:username],params[:session][:password])
    else
      @account = Account.user_authenticate(params[:session][:username],params[:session][:password])
    end

    if @account
  		sign_in(@account,params[:remember_me])
             #update cart
             # @line_items.update_all(:member_id=>@account.account_id,
             #                                       :member_ident=>Digest::MD5.hexdigest(@account.account_id.to_s))
      if @account.member.card_validate=='false'
          @return_url = new_member_path
      end
  		render "create"
  	else

  		render "error"
      #  render js: '$("#login_msg").text("帐号或密码错误!").addClass("error").fadeOut(300).fadeIn(300);'
  	end
  end

  def destroy
      sign_out
       refer_url = request.env["HTTP_REFERER"]
       refer_url = "/" unless refer_url

       redirect_to refer_url

  end


end
