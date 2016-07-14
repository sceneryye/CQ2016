require 'digest/md5'
require 'hashie'
require 'pp'
class Auth::WeixinController < ApplicationController
	skip_before_filter :authorize_user!

	def index 
		auth_ext = AuthExt.find_by_id(cookies.signed[:_auth_ext].to_i) if cookies.signed[:_auth_ext]
		session[:from] = "external_auth"
		
		if auth_ext&&!auth_ext.expired?&&auth_ext.provider == 'weixin'
			if auth_ext.account.nil?
				cookies.delete :_auth_ext
				redirect_to  Weixin.authorize_url
			else
				sign_in(auth_ext.account)
				redirect_to after_user_sign_in_path
			end
		else
			redirect_to Weixin.authorize_url
		end
	end

	def callback

		supplier_id = params[:id]

		return redirect_to(site_path) if params[:error].present?
	    return_url = session[:return_url]
	    if return_url
          redirect = return_url
      	else
	      redirect = after_user_sign_in_path
	    end
	    session[:return_url] = nil

		token = Weixin.request_token(params[:code],supplier_id.to_i)
		# {"access_token":"irSnkAt_ZQLwFZ2CvFk-s7-9RYqwD8ImlwXhjmDwhpOiHu6kjZUMPHyXurmH-pKVBuvOaFOXaKczV210PkYzxRAVKO1Me6nBmQeV3nDO42w",
		# 	"expires_in":7200,
		# 	"refresh_token":"hEGENJdVp_KKZiXm-X8CoMliUxNrsMz9VB_UUcxX79YgKlOEZ1fTp6fyTSpnTQiPyEmt2u6ipgXevc1_OW5EX_D_GqO1x31U7tQwESk7pyk",
		# 	"openid":"ojvSyw4gaxg22xdTMHGVAvuD46KQ",
		# 	"scope":"snsapi_login",
		# 	"unionid":"oxKrEuBgzuxUBJzZghogSkygibSw",
		# 	"expires_at":1464870964}

	   	#return render text: token.to_json

	   	@account = Account.where(login_name: token.unionid.to_s)
	   	# return render text: token.unionid.to_s==@account.first.login_name
	   	# return render text: @account.to_json
	   	if @account.nil?
			auth_ext = AuthExt.where(:provider=>"weixin",
										:uid=>token.unionid).first_or_initialize(
										:access_token=>token.access_token,
	  								#   :refresh_token=>token.refresh_token,
										:expires_at=>token.expires_at,
										:expires_in=>token.expires_in)

			#return render text: auth_ext.new_record? || auth_ext.account.nil? || auth_ext.account.user
			if auth_ext.new_record? || auth_ext.account.nil? || auth_ext.account.user.nil?
				client = Weixin.new(:access_token=>token.access_token,:expires_at=>token.expires_at)
				#auth_user = client.get('users/show.json',:uid=>token.openid)
				#return  render :text=>auth_user .to_json
				#logger.info auth_user.inspect
				# return  render :text=>client.to_json
		    	login_name = token.unionid
	    		#  return render :text=>login_name
				check_user = Account.find_by_login_name(login_name)

				if check_user.nil?
					now = Time.now

					if supplier_id ==1
						@openid  = token.openid
					end

					@account = Account.new  do |ac|
						#account
						ac.login_name = login_name
						ac.login_password = login_name[0,6]#'123456'
				  		ac.account_type ="member"
				  		ac.createtime = now.to_i
				  		ac.openid = @openid
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
				  		end
			  		end
			  	else
			  		@account = check_user
				end

			else
				@account = auth_ext.account	    			    
			end
		else
			@account = @account.first
		end

# return render text: @account.to_json
		sign_in(@account,'1')	

		if supplier_id.to_i == 1
			if current_account.openid.nil?
				@account.update_attribute :openid ,token.openid
			end
		end

		if current_account.member.card_validate=='false'
	    	redirect =  new_member_path
	    end	

		redirect_to redirect
	end

	def cancel
	end

	private
	def account
	    params.require(:account).permit(:openid)
	end
end