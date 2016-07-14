#encoding:utf-8
require 'sms'
require 'allinpay'
class Memberships::CardsController < ApplicationController
	before_filter :authorize_user!
	# skip_before_filter :authorize_user!
	before_filter :find_user
	layout 'application'

  	include Allinpay

  	def subcards
  		@subcards = @user.member_card.subcards
  	end

  	def new () end

  	def create
  		
		@card = Card.find_by_no(card_params[:no])
		if @card && @card.status=='未激活'#@card.can_use? && !@card.used?
  			card_no = card_params[:no]
			password = card_params[:password]

			card_info = card_info('会员卡激活', password, card_no)

	        if card_info[:error]
	        	flash[:error] = card_info[:error] 
				return render 'new'
	        else				
	        	@user.update_attribute :card_num ,card_no
				@user.update_attribute :card_validate,'true'
				@card.update_attribute :use_status,true
				@card.update_attribute :used_at,Time.now
				@card.update_attribute :status,'已使用'
				
				if @card.member_card.nil?
					@member_card = MemberCard.new do |member_card|
						member_card.user_id = @user.member_id
						member_card.member_id = @user.member_id
						member_card.card_id = @card.id
						member_card.user_name = @user.name
						member_card.user_tel = @user.mobile
					end
					@member_card.save!
				else
					@card.member_card.update_attribute :user_id,@user.member_id
					@card.member_card.update_attribute :member_id,@user.member_id
					member_card.card_id = @card.id
				end

				#发微信通知
				send_message('激活')

				CardLog.create(:member_id=>@user.member_id,
	                                                :card_id=>@card.id,
	                                                :message=>"会员卡激活,会员本人操作")
				@password = session[:card_pwd]
				@return_url = bank_cards_path
				flash[:error] = "为了账号安全,请您立刻修改初始密码！" 
				return render 'edit'

			end
		else
			
			flash[:error] = "会员卡无法激活" 
			return render 'new'
		end
	end

	def member_card
		@member_card = @user.member_card
	    if @member_card.update_attributes(member_card_params)
	    	redirect_to card_path(0), notice: '恭喜你！会员卡激活成功！'
	    else
	    	flash[:error] = "银行卡验证失败" 
	    	render 'bank'
	    end
	end

  	def login
  		@return_url = params[:return_url]

	    password = params[:card][:password]
	    from = params[:from]

	    card_info = card_info(from,password)
		if card_info[:error]
			redirect_to @return_url,notice: card_info[:error]
		else
			redirect_to @return_url
		end
  	end

  	def show
  		if session[:card_pwd] && params[:id]=='2'
  			card_info '查询余额'
  		end

  		@current ='余额查询'
  		if params[:id]=='0'
  			@current='会员卡信息'
  		end
  		
  		@card_info = MemberAdvance.where(member_id: @user.member_id).last
	end

  	def recharge () end

  	def topup
  		card_id = @user.card_num;
    	amount =  ((params[:amount].to_f)*100).to_i
    	opr_id = '0229000040'
	    
	    desn = params[:desn]
	    res_data = ActiveSupport::JSON.decode topup_single_card(card_id, amount, opr_id, desn)

	    res_info = save_log res_data

	    if res_info[:error]
	    	return render text: res_info[:error]
	    else
	    	card_info = card_info('充值')
	    	redirect_to card_path(1), notice: "成功充值：#{params[:amount]}"
	    end
	end

  	def edit () end

  	def update
	    card_id = @user.card_num
	    @return_url = params[:return_url]
	    old_pwd = params[:card][:old_pwd]
	    new_pwd = params[:card][:new_pwd]
	    new_pwd_repeat = params[:card][:new_pwd_repeat]

	    if new_pwd != new_pwd_repeat
	    	flash[:error] = "两次输入的新密码不同" 
	    	return render 'edit'
	    end

	    card_info = card_info('修改密码',old_pwd)

	    if card_info[:error]
	    	flash[:error] = "原密码不正确" 
	    	return render 'edit'
		else
			
			# reset_password
		    res_data = ActiveSupport::JSON.decode card_reset_password(card_id, new_pwd)
		    card_info = card_info('修改密码后查询',new_pwd)
		    if @return_url == bank_cards_path
		    	return redirect_to @return_url, notice: '密码修改成功！请绑定您的银行卡，用于以后提现收款，谢谢。'
		    else

			    session[:card_pwd] = nil
			   	redirect_to member_path, notice: '密码修改成功'
		   end
		end	
	end

	def index
	    @rebate_availabe = @user.rebates.where(status:0).sum(:amount)
		@withdrawal_total =  @user.withdrawals.sum(:amount)
		@withdrawal_this_week = @user.withdrawals.where('updated_at>?',Time.now.beginning_of_week).sum(:amount)
	end

	def tradings
		if  @user
	    	@tradings = CardTrading.where(card_no: @user.card_num).order("created_at desc").paginate(:page=>params[:page],:per_page=>20)

	    else
	      redirect_to "/auto_login?#{return_url}&id=1"
	    end   
	end

	def rebates
		@status = params[:status].to_i
		if @status.blank?
			@status = 0		
		end
		if @status == 0
			@no='disabled'
		else
			@yes = 'disabled'
		end	

		@rebates =  @user.rebates.where(status: @status).paginate(:page=>params[:page],:per_page=>20)		
	end  	

	def pay
		pay_params = params[:card]
	    mer_order_id = "#{pay_params[:order_id]}_#{rand(100).to_s}"
  		card_id = @user.card_num;
	    amount = pay_params[:amount].to_i*100
	    password = pay_params[:password]
	    res_data = ActiveSupport::JSON.decode pay_with_password(amount, card_id, password,mer_order_id)
	    res_info = save_log res_data

	    if res_info[:error]
	    	redirect_to order_path(pay_params[:order_id]), notice: res_info[:error]
	    else

	    	@trading = CardTrading.new do |trading|
	    		trading.card_no = card_id
	    		trading.card_id = @user.member_card.card_id
	    		trading.amount = pay_params[:amount]
	    		trading.trading_time = Time.now
	    		trading.order_id = pay_params[:order_id]
	    	end
	    	if @trading.card.card_type=='B'

	    		rate = 0.1
	    		parent_rate =0.15
	    	else
	    		rate = 0.15
	    	end

	    	if @trading.save
	    		@rebate = Rebate.new do |rebate|
		    		rebate.member_id = @user.member_id
		    		rebate.card_id = @trading.card_id
		    		rebate.card_trading_id = @trading.id
		    		rebate.rate = rate
		    		rebate.amount = @trading.amount * rate 
		    		rebate.rebate_type = '0'
		    	end
		    	if @rebate.save && @trading.card.card_type=='B'
		    		@rebate = Rebate.new do |rebate|
			    		rebate.member_id = @trading.card.parent_card.member_card.member_id
			    		rebate.card_id = @trading.card_id
			    		rebate.card_trading_id = @trading.id
			    		rebate.rate = parent_rate
			    		rebate.amount = @trading.amount * parent_rate 
			    		rebate.rebate_type = '1'
			    	end
			    	@rebate.save!
			    end
	    	end

	    	card_info = card_info('支付')
	    	redirect_to payments_path(order_id: pay_params[:order_id])
	    end
	end	

	def withdrawals
		@withdrawals = @user.withdrawals.paginate(:page=>params[:page],:per_page=>20)
	end

	def apply_withdrawal
		if @user.member_card.bank_card_no.blank?
			return redirect_to bank_cards_path, notice: "绑定银行后才能提现" 
		end
		@rebates = @user.rebates.where(status:0)
		amount = @rebates.sum(:amount) #@tradings.collect { |trading| trading.amount }.inject(:+).to_f
		rebate_ids =@rebates.collect { |rebate| rebate.id.to_s }.join(',')

		@withdrawal = Withdrawal.new do |withdrawal|
			withdrawal.member_id = @user.member_id
			withdrawal.amount = amount
			withdrawal.rebate_ids = rebate_ids
		end
		if @withdrawal.save!				
			@rebates.update_all("status=1,withdrawal_id=#{@withdrawal.id}")
			redirect_to withdrawals_cards_path, notice: '提现申请成功'
	    else
	    	redirect_to rebates_cards_path(status:0), notice: "提现申请失败" 
	    end
	end

	def renew_record

  		begin_date = params[:begin_date] 
	    end_date = params[:end_date]
	    card_id = params[:card_id]
	    password = params[:password]
	    page_no = params[:page_no]
	    page_size = params[:page_size]
	    return render json: {data: {error_message: '不能查询90天之前的记录！'}} if Time.parse(begin_date) < (Time.now - 3600 * 24 * 90)
	    res_data = ActiveSupport::JSON.decode card_get_trade_log(begin_date, end_date, card_id, password, page_no, page_size)
	    Rails.logger.info res_data
	    render json: {data: res_data}
  	end	

	def pay_to_client
	    data = params[:pay_to_client]
	    res_data = Hash.from_xml pay_for_another data
	    render json: {data: res_data}
	end
	

	private
	def card_params
	    params.require(:card).permit(:no,:password)
	end

	def member_card_params
	    params.require(:member_card).permit(:bank_name,:bank_card_no,:bank_branch)
	end

	def card_info (from='',password=session[:card_pwd],card_id=@user.card_num )

		if password.blank?
			return {error:'login'}
		end
		@cards_log ||= Logger.new('log/cards.log')

	  	res_data = ActiveSupport::JSON.decode card_get_info(card_id, password)

	    @cards_log.info("[#{@user.login_name}][#{Time.now}]#{res_data}")

	    @card_log = CardLog.create(:member_id=>@user.member_id,
										:card_no=>card_id,
										:message=>"#{res_data.to_json}")

	    if res_data["error_response"]
	 		@cards_log.info("[#{@user.login_name}][#{Time.now}]查询会员卡信息失败")	  
	 		return {error:res_data["error_response"]["sub_msg"]} 	
			###########e.data.ppcs_cardsingleactive_add_response# e.data.error_response.sub_msg					
		else
			
			#{"data":{"card_cardinfo_get_response":{"res_timestamp":20160406213434,"res_sign":"77AFA3C325F8E63404A573B3C306E468","card_info":{"card_stat":0,"brh_id":"0229000040","brand_id":"0001","validity_date":20170210,"card_id":8668083660000001017,"card_product_info_arrays":{"card_product_info":[{"product_stat":0,"product_id":"0001","product_name":"通用金额","validity_date":20170210,"valid_balance":476631,"card_id":8668083660000001017,"account_balance":486631},{"product_stat":0,"product_id":"0282","product_name":"200元现金券","validity_date":20991231,"valid_balance":553619,"card_id":8668083660000001017,"account_balance":553619},{"product_stat":0,"product_id":1000,"product_name":"提现","validity_date":20160210,"valid_balance":1745700,"card_id":8668083660000001017,"account_balance":1745700}]}}}}}
     		info = res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]
	        status = case info["product_stat"]
	          		when 0
	          			 '正常'
	          		when 1
	          			'挂失'          
	          		when 2
	          			'冻结'          
	          		when 3
	         			'作废'          
	          		else 
	          			'未知'          
	        end
	         #   message = '卡号：' + card_id + ';  认证日期：' + e.data.card_cardinfo_get_response.card_info.validity_date +';  余额：' + parseFloat(msg.account_balance / 100) + '元' + ';  产品名称：' + msg.product_name + ';  可用余额：' + parseFloat(msg.valid_balance / 100) + '元' + ';  产品有效期：' + msg.validity_date + ';  产品状态：' + state;
	        balance = (info["valid_balance"].to_f)/100
			
			MemberAdvance.create(:member_id=>@user.member_id,
										  :money=>balance,
										  :message=>"#{from},卡号:#{card_id}",
										  :mtime=>Time.now.to_i,
										  :memo=>"会员本人操作",
										  :import_money=>balance,
										  :explode_money=>0,
										  :member_advance=>balance,
										  :shop_advance=>balance,
										  :disabled=>'false')
			@user.update_attribute :advance, balance

	        session[:card_pwd] = password

	    end
	    return {status: status, balance: balance}
	end


	def save_log (res_data,from='')
		card_no = @user.card_num
		card_id = Card.find_by_no(card_no)[:id]
		member_id = @user.member_id
		@cards_log ||= Logger.new('log/cards.log')

	    @cards_log.info("[#{@user.login_name}][#{Time.now}]#{res_data}")

	    @card_log = CardLog.create(:member_id=>@user.member_id,
										:card_no=>card_no,
										:card_id=>card_id,
										:message=>"#{res_data.to_json}")

	    if res_data["error_response"]
	 		@cards_log.info("[#{@user.login_name}][#{Time.now}]操作失败")	  
	 		return  {error:res_data["error_response"]["sub_msg"]} 	
			###########e.data.ppcs_cardsingleactive_add_response# e.data.error_response.sub_msg					
		else
			balance = import_money = explode_money = 0
									     		
     		if res_data["card_paywithpassword_add_response"].present?
     			from = '密码支付'
     			#{"card_paywithpassword_add_response":{"res_timestamp":20160414050912,"res_sign":"778D195C92769B4C8356CE05F553A0B4","pay_result_info":{"amount":5400,"pay_txn_id":"0003951534","mer_order_id":20160414048398,"mer_id":999990053990001,"pay_cur":"CNY","pay_txn_tm":20160116051038,"mer_tm":20160414051058,"payment_id":"0000000001","type":"01","card_id":8668083660000001017,"stat":1},"order_id":"999990053990001_146058185899"}}
     			result_info  = res_data["card_paywithpassword_add_response"]["pay_result_info"]
	     		explode_money = result_info["amount"].to_f/100
	     		# money = card_info ('pay')[:blance]

     		elsif res_data["card_cardinfo_get_response"].present?
     			from = '查询卡信息'
     			#{"card_cardinfo_get_response":{"res_timestamp":20160406213434,"res_sign":"77AFA3C325F8E63404A573B3C306E468","card_info":{"card_stat":0,"brh_id":"0229000040","brand_id":"0001","validity_date":20170210,"card_id":8668083660000001017,"card_product_info_arrays":{"card_product_info":[{"product_stat":0,"product_id":"0001","product_name":"通用金额","validity_date":20170210,"valid_balance":476631,"card_id":8668083660000001017,"account_balance":486631},{"product_stat":0,"product_id":"0282","product_name":"200元现金券","validity_date":20991231,"valid_balance":553619,"card_id":8668083660000001017,"account_balance":553619},{"product_stat":0,"product_id":1000,"product_name":"提现","validity_date":20160210,"valid_balance":1745700,"card_id":8668083660000001017,"account_balance":1745700}]}}}}
		        status = case res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]["product_stat"]
		          		when 0
		          			 '正常'
		          		when 1
		          			'挂失'          
		          		when 2
		          			'冻结'          
		          		when 3
		         			'作废'          
		          		else 
		          			'未知'          
		        end
		         #   message = '卡号：' + card_id + ';  认证日期：' + e.data.card_cardinfo_get_response.card_info.validity_date +';  余额：' + parseFloat(msg.account_balance / 100) + '元' + ';  产品名称：' + msg.product_name + ';  可用余额：' + parseFloat(msg.valid_balance / 100) + '元' + ';  产品有效期：' + msg.validity_date + ';  产品状态：' + state;
		        balance = res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]["valid_balance"]
		        balance = (balance.to_f)/100		

     		elsif res_data["ppcs_cardsingletopup_add_response"].present?
     			from = '单卡充值'
     			#{"ppcs_cardsingletopup_add_response"=>{"res_timestamp"=>20160411140644, "res_sign"=>"9EFBFD4D562A5472E5F8B334F20BC45E", "trans_no"=>"0003950251", "result_info"=>{"amount"=>1000, "prdt_no"=>"0001", "validity_date"=>20170210, "top_up_way"=>1, "valid_balance"=>201771, "card_id"=>8668083660000001017, "account_balance"=>211771, "desn"=>""}, "order_id"=>"999990053990001_146035491139"}}
     			result_info  = res_data["ppcs_cardsingletopup_add_response"]["result_info"]
	     		import_money = result_info["amount"].to_f/100
	     		money = result_info["account_balance"].to_f/100
     		end

     		
     		MemberAdvance.create(:member_id=>@user.member_id,
										  :money=>balance,
										  :message=>"#{from},卡号:#{card_no}",
										  :mtime=>Time.now.to_i,
										  :memo=>"#{from}-会员本人操作",
										  :import_money=>import_money,
										  :explode_money=> explode_money,
										  :member_advance=>balance,
										  :shop_advance=>balance,
										  :disabled=>'false')
			@user.update_attribute :advance, balance

			return {import_money: import_money, balance: balance}
	
			
		end
	end

	def send_message (message)
		# begin
		# 	@weixin_log ||= Logger.new('log/weixin.log')

		# 	text = "您的昌麒会员卡#{@card.no}已激活,如有疑问请致电客服400-826-4568[CQ昌麒]"
		# 	# if weixin.send(@card.member_card.user_tel,text)
		# 	# 	tel = @card.member_card.user_tel
		# 	# 	@weixin_log.info("[#{@user.login_name}][#{Time.now}][#{tel}]#{text}")
		# 	# end
		# rescue
		# 	@weixin_log.info("[#{@user.login_name}][#{Time.now}]激活会员卡,发送微信失败")
		# end
	end
end
