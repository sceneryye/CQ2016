#encoding:utf-8
require 'sms'
class Admin::UsersController < Admin::BaseController

	def search
		type = params[:search][:type]
		key = params[:search][:key]
		@member_type = params[:search][:member_type]

		@card = Card.find(params[:card_id])

		if type == 'login_name'
			account = Account.find_by_login_name(key)
			@user = account.user  if account

		else
			# @users = MemberCard.where("user_tel = ? and user_id is not null",key).collect do |mc|
			# 	mc.user
			# end.uniq
			@users = User.where(:mobile=>key)
			if @users.size <= 1
				@user = @users.first
				@users = nil
			end
		end

		respond_to do |format|
			format.js
		end
		
	end

	def newuser
		account = Account.new
		account.account_type = "shopadmin"
		account.login_name = params[:manager][:name]
		account.login_password = params[:manager][:password]
		account.createtime = Time.now.to_i
		account.login_password_confirmation = params[:manager][:password]
		account.email = params[:manager][:email]
		account.mobile = params[:manager][:mobile]
		account.license = true
		account.save!
		manager = Manager.new
		manager.user_id = account.account_id
		manager.status = 1
		manager.name = params[:manager][:desc]
		manager.save!
		redirect_to admin_permissions_path
	end


	def send_sms_code

		@user = User.find(params[:id])

		sms_code = rand(1000000).to_s(16)
		tel = params[:tel]
		text = "您的会员卡验证码是：#{sms_code}，如此条验证码非您本人申请，请立即致电客服021-22306630核实[CQ2016]"

		
		@sms_log ||= Logger.new('log/sms.log')
		if Sms.send(tel,text)
			@sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{tel}]发送手机验证码: #{sms_code}")
			@user.update_attribute :mobile, tel if @user.mobile.blank?
			@user.update_attribute :sms_code, sms_code

			render :json=>{:code=>'t',:msg=>'验证码已发送'}.to_json
		end

		rescue Exception=> e
			@sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{tel}]发送手机验证码失败:#{e}")
			render :json=>{ :code=>'f',:msg=>e }.to_json
	end

	def validate_mobile
		@user = User.find(params[:id])
		mobile = params[:mobile]

		@user.update_attributes({:mobile=>mobile,:sms_validate=>'true'})

		render "validate_mobile"
	end

	def select
		@user = User.find(params[:id])
		@card = Card.find(params[:card])
		@member_type = params[:member_type]
		render "select"
	end


	def buy_card

		@buyer = User.find(params[:id])

		@card = Card.find(member_card_params[:card_id])

		return render(:js=>"alert('不能购买,请检查卡状态!')") unless  @card.can_buy?

		validate_type = params[:member_card].delete :validate_type

		# if !@buyer.sms_validated?
		# 	@buyer_card.errors.add(:buyer_tel,"请先在我的昌麒/个人信息管理/账户中心 认证手机号码")
		# 	return render("buy_card")
		# end

		if validate_type == 'sms'
			if member_card_params.has_key?(:sms_code) &&
				member_card_params.delete(:sms_code) != @buyer.sms_code

				@buyer_card.errors.add(:buyer_tel,"请填写手机号码") if member_card_params[:buyer_tel].blank?
				@buyer_card.errors.add(:user_tel,"请填写手机号码") if member_card_params[:user_tel].blank?
				@buyer_card.errors.add(:sms_code,'手机验证码错误')

				return render("buy_card")
			end
		else
			member_card_params.delete(:sms_code)
		end

		if (pay_status = params[:member_card].delete(:pay_status)) == 'false'
			member_card_params.delete :bank_name
			member_card_params.delete :bank_card_no
		end
		@buyer_card = MemberCard.new(member_card_params)

		messages =  member_card_params.dup

		if  @buyer_card.save

			# update pay_status
			if pay_status == 'true'
				@card.update_attribute :pay_status, true
				messages.merge! :pay_status=> true
			else
				messages.merge! :pay_status=> false
			end

			if validate_type == "hand"
				messages.merge! :validate_type=>"直接通过验证"
			else
				messages.merge! :validate_type=> "手机验证码"
			end
			
			#update buyer sms_validate 
			@buyer.update_attribute :mobile, member_card_params[:buyer_tel]
			@buyer.update_attribute :sms_validate, 'true'

			
			messages.delete :card_id
			log = messages.collect do |key,value|

				if %w(user_id buyer_id).include?(key)
					u = User.find(value)
					value = u.account.login_name if u&&u.account
				end

				value = "是" if value.is_a?(TrueClass)
				value = "否" if value.is_a?(FalseClass)

				I18n.t("card.#{key}") + "=" + value.to_s

			end.join(",")

			CardLog.create(:member_id=>current_admin.account_id,
                                                :card_id=>@card.id,
                                                :message=>"购买: #{log}")
		end

		render "buy_card"
	end

	def use_card
		@user = User.find(member_card_params[:user_id])
		@card = Card.find(member_card_params[:card_id])

		return render(:js=>"alert('不能使用该卡,请检查卡状态!')") unless  @card.can_use?

		is_valid = true

		if @card.card_type == "B"
			if member_card_params.delete(:password) != @card.password
				@user.errors.add :password, "卡密码错误"
				is_valid = false
			end
		end

		# if member_card_params.delete(:sms_code) != @user.sms_code
		# 	@user.errors.add :sms_code, "手机验证码错误" 
		# 	is_valid = false
		# end


		if is_valid && @card.can_use?

			advance = @user.member_advances.order("log_id asc").last
			shop_advance = 0
			 if advance
				shop_advance = advance.shop_advance
			else
				shop_advance = @user.advance
			end
			shop_advance += @card.value
			MemberAdvance.create(:member_id=>@user.member_id,
											  :money=>@card.value,
											  :message=>"会员卡激活,卡号:#{@card.no}",
											  :mtime=>Time.now.to_i,
											  :memo=>"管理操作",
											  :import_money=>@card.value,
											  :explode_money=>0,
											  :member_advance=>(@user.advance + @card.value),
											  :shop_advance=>shop_advance,
											  :disabled=>'false')
			@user.update_attribute :advance, @card.value + @user.advance
			@card.update_attribute :use_status, true
			@card.update_attribute :used_at, Time.now
			@card.member_card.update_attributes(member_card_params)

			member_card_params.delete :card_id
			log = member_card_params.collect do |key,value|
				if %w(user_id buyer_id).include?(key)
					u = User.find(value)
					value = u.account.login_name if u&&u.account
				end
				value = "是" if value.is_a?(TrueClass)
				value = "否" if value.is_a?(FalseClass)
				I18n.t("card.#{key}") + "=" + value.to_s
			end.join(",")

			CardLog.create(:member_id=>current_admin.account_id,
			                                         :card_id=>@card.id,
			                                         :message=>"充值: #{log}, 金额=#{@card.value}")
		end

		render "use_card"
	end
	private
	def member_card_params
		params.require(:member_card).permit(:buyer_tel,:bank_name,:bank_card_no,:user_tel,:card_id,:user_id,:buy_id,:pay_status)
	end

end
