#encoding : UTF-8
class WechatController < ApplicationController

def callback
    app_id = params[:id]

    return redirect_to(site_path) if params[:error].present?
      return_url= session[:return_url]
      session[:return_url]=''

  
    token = Weixin.request_token(params[:code])
     #return  render :text=>token.to_json

    auth_ext = AuthExt.where(:provider=>"weixin",
                  :uid=>token.openid).first_or_initialize(
                  :access_token=>token.access_token,
  #                :refresh_token=>token.refresh_token,
                  :expires_at=>token.expires_at,
                  :expires_in=>token.expires_in)

    if return_url
          redirect = return_url
        else
        redirect = after_user_sign_in_path
      end

    if auth_ext.new_record? || auth_ext.account.nil? || auth_ext.account.user.nil?
      client = Weixin.new(:access_token=>token.access_token,:expires_at=>token.expires_at)
      # auth_user = client.get('users/show.json',:uid=>token.openid)
      #return  render :text=>auth_user .to_json
      #logger.info auth_user.inspect
        login_name = token.openid
        #  return render :text=>login_name
      check_user = Account.find_by_login_name(login_name)

      if check_user.nil?
        now = Time.now
        @account = Account.new  do |ac|
          #account
          ac.login_name = login_name
          ac.login_password = login_name[0,6]#'123456'
            ac.account_type ="member"
            ac.createtime = now.to_i
            # auth_ext
            ac.auth_ext = auth_ext

              ac.supplier_id = supplier_id            
          end
          Account.transaction do
            if @account.save!(:validate => false)
              @user = User.new do |u|
                u.member_id = @account.account_id
                u.email = "weixin_user#{rand(9999)}@anonymous.com"
                #u.sex = case auth_user.gender when 'f'; '0'; when 'm'; '1'; else '2'; end if auth_user
                u.member_lv_id = 1
                u.cur = "CNY"
                u.reg_ip = request.remote_ip
                #u.addr = auth_user.location || auth_user.loc_name if auth_user
                u.regtime = now.to_i
              end
              @user.save!(:validate=>false)
              sign_in(@account,'1')
              return redirect_to new_member_path
            end
          end
        else
          sign_in(check_user,'1')
         
          if current_account.member.card_validate=='false'
            redirect =  new_member_path
          end 
          return redirect_to redirect
      end

    else
      sign_in(auth_ext.account,'1')
      # return redirect_to "/member/new?return_url=#{redirect}"
        
        if current_account.member.card_validate=='false'
          redirect =  new_member_path
        end 
        redirect_to redirect
    end
  end


end