#encoding:utf-8
require  'modec_pay'
class Store::PaymentsController < ApplicationController
	layout 'order'

	skip_before_filter :verify_authenticity_token,:only=>[:callback,:notify]

	def index
		rel_id = params[:order_id]
		@order  = Order.find_by_order_id(rel_id)
		installment =  1
		part_pay =  0

		pay_app_id ='deposit' #payment_params[:pay_app_id]

		
		#  update order payment
		@order.update_attributes :payment=>pay_app_id,:last_modified=>Time.now.to_i,:installment=>installment,:part_pay=>part_pay if pay_app_id.to_s != @order.payment.to_s

		# payment_params.merge! Payment::PAYMENTS[pay_app_id.to_sym]

		@payment = Payment.new   do |payment|
			payment.payment_id = Payment.generate_payment_id
			payment.pay_app_id = pay_app_id
			payment.status = 'ready'
			payment.pay_ver = '1.0'
			payment.paycost = 0

			payment.account = '昌麒投资'
			payment.member_id = payment.op_id = @user.member_id
			payment.pay_account = @user.login_name
			payment.ip = request.remote_ip

			payment.t_begin = payment.t_confirm = Time.now.to_i
			
			payment.pay_bill = Bill.new do |bill|
				bill.rel_id  = rel_id
				bill.bill_type = "payments"
				bill.pay_object  = "order"
				bill.money = @order.pay_amount
			end
		end

		@payment.money = @payment.cur_money = @order.pay_amount
		if @payment.save
        	redirect_to "/payments/pay?id=#{@payment.payment_id}"
		else			
			redirect_to order_url(@order)
		end
  	end
 
	def create
		rel_id = params[:order_id]
		@order  = Order.find_by_order_id(rel_id)
		installment = payment_params.delete(:installment) || 1
		part_pay = payment_params.delete(:part_pay) || 0

		pay_app_id = payment_params[:pay_app_id]

		if part_pay == 0 && @order.part_pay?
			@user.update_column :advance, @order.part_pay
			@user.update_column :advance_freeze, @user.advance_freeze - @order.part_pay
		end

		#  update order payment
		@order.update_attributes :payment=>pay_app_id,:last_modified=>Time.now.to_i,:installment=>installment,:part_pay=>part_pay if pay_app_id.to_s != @order.payment.to_s

		payment_params.merge! Payment::PAYMENTS[pay_app_id.to_sym]

		@payment = Payment.new payment_params  do |payment|
			payment.payment_id = Payment.generate_payment_id

			payment.status = 'ready'
			payment.pay_ver = '1.0'
			payment.paycost = 0

			payment.account = '昌麒投资'
			payment.member_id = payment.op_id = @user.member_id
			payment.pay_account = @user.login_name
			payment.ip = request.remote_ip

			payment.t_begin = payment.t_confirm = Time.now.to_i
			
			payment.pay_bill = Bill.new do |bill|
				bill.rel_id  = rel_id
				bill.bill_type = "payments"
				bill.pay_object  = "order"
				bill.money = @order.pay_amount
			end
		end

		@payment.money = @payment.cur_money = @order.pay_amount
		if @payment.save
        	redirect_to "/payments/pay?id=#{@payment.payment_id}"
		else			
			redirect_to order_url(@order)
		end
  	end

  	def add_advance

  		pay_amount = params[:payment][:amount]
  		
  		#pay_amount = 0.01 #测试充值用

  		payment_params = {
				  		:money => pay_amount,
				  		:cur_money => pay_amount,
						:pay_app_id => 'wxpay'
						}
		
		payment_params.merge! Payment::PAYMENTS[payment_params[:pay_app_id].to_sym]

		@payment = Payment.new payment_params do |payment|
			payment.payment_id = Payment.generate_payment_id
			payment.currency='CNY'
			payment.status = 'ready'
			payment.pay_ver = '1.0'
			payment.paycost = 0

			payment.account = '昌麒投资'
			payment.member_id = payment.op_id = @user.member_id
			payment.pay_account = @user.login_name
			payment.ip = request.remote_ip

			payment.t_begin = payment.t_confirm = Time.now.to_i
			
			payment.pay_bill = Bill.new do |bill|
				bill.rel_id = Time.now.strftime('%Y%m%d%H%M%S')
				bill.bill_type = "refunds"
				bill.pay_object  = "prepaid_recharge"
				bill.money = payment_params[:money]
			end
		end

		if @payment.save
			redirect_to "/payments/pay?id=#{@payment.payment_id}"
        	# redirect_to topup_cards_path(amount: pay_amount )
		else			
			redirect_to recharge_cards_path,notice:'充值不成功'
		end
  	end

	def show
		@payment = Payment.find_by_payment_id(params[:id])
	end

	def pay
		@payment = Payment.find(params[:id])
      	if @payment && @payment.status == 'ready'
	        adapter = @payment.pay_app_id
	        order_id = @payment.pay_bill.rel_id
	        @modec_pay = ModecPay.new adapter do |pay|
	        	pay.return_url = "#{site}/payments/#{@payment.payment_id}/#{adapter}/callback"
		        pay.notify_url = "#{site}/payments/#{@payment.payment_id}/#{adapter}/notify"		        
		        # pay.return_url = "#{site}/payments/#{adapter}/callback?payment_id=#{@payment.payment_id}"
		        # pay.notify_url = "#{site}/payments/#{adapter}/notify?payment_id=#{@payment.payment_id}"
				pay.pay_id = @payment.payment_id
				pay.pay_amount = @payment.cur_money.to_f
				pay.pay_time = Time.now
				pay.subject = "昌麒投资订单(#{order_id})"
				pay.installment = @payment.pay_bill.order.installment if @payment.pay_bill.order
		        pay.openid = @user.account.openid
		        pay.spbill_create_ip = request.remote_ip
		    end

		    if adapter=='alipaywap'
		        render :text=>@modec_pay.html_form_alipaywap
		    elsif adapter=='wxpay'
		        render :inline=>@modec_pay.html_form_wxpay
		     # render :inline=>@modec_pay.html_form_wxpay, :layout=>"application"
		    else
		    	if adapter=='deposit'
		    		advance = @user.advance
		    		Member.where(:member_id=>@user.member_id).update_all(:advance=>advance-@payment.cur_money)
			        @adv_log ||= Logger.new('log/adv.log')
			        @adv_log.info("member id: "+@user.member_id.to_s+"--advance:"+advance.to_s+"=>"+@user.advance.to_s)
		    	end
				render :inline=>@modec_pay.html_form
		    end

			PaymentLog.new do |log|
				log.payment_id = @payment.payment_id
				log.order_id = order_id
				log.pay_name = adapter
				log.request_ip = request.remote_ip
				log.request_params = @modec_pay.fields.to_json
				log.requested_at = Time.now
			end.save

		else
			flash[:msg] = '不能支付,请查看订单状态'
		end
	end

	def callback
		@payment = Payment.find(params.delete(:id))
		order_id = @payment.pay_bill.order
		if params[:error_message]
			return redirect_to recharge_cards_path,notice:'充值不成功:#{params[:error_message]}' #order_path(order_id)
			#return render :text=>"支付不成功。error_message:#{params[:error_message]}"
		end

		ModecPay.logger.info "[#{Time.now}][#{request.remote_ip}] #{request.request_method} \"#{request.fullpath}\""

		
		#@payment = Payment.find(params[:payment_id])	

		
		return redirect_to detail_order_path(order_id) if @payment&&@payment.paid?
		
		adapter  = params.delete(:adapter)
		params.delete :controller
		params.delete :action

		@payment.payment_log.update_attributes({:return_ip=>request.remote_ip,:return_params=> params,:returned_at=>Time.now}) if @payment.payment_log

		if @payment.pay_bill.bill_type =='payments' && @payment.pay_bill.pay_object == 'order'
			@order = @payment.pay_bill.order
		end
		order_id = @payment.pay_bill.rel_id

		@user = @payment.user
		result = ModecPay.verify_return(adapter, params, {:ip=>request.remote_ip })		

		if result.is_a?(Hash) && result.present?
			response = result.delete(:response)
			if result.delete(:payment_id) == @payment.payment_id.to_s && !@payment.paid?
				@payment.update_attributes(result)
				@order.update_attributes(:pay_status=>'1')
				OrderLog.new do |order_log|
					order_log.rel_id = order_id #@order.order_id
					order_log.op_id = @user.member_id
					order_log.op_name = @user.login_name
					order_log.alttime = @payment.t_payed
					order_log.behavior = 'payments'
					order_log.result = "SUCCESS"
					order_log.log_text = "订单支付成功！"
				end.save
			end
		else
			response =  result
		end
		if @payment.pay_bill.bill_type =='payments' && @payment.pay_bill.pay_object == 'order'
			redirect_to detail_order_path(@payment.pay_bill.order)
		else
			# @member = Member.find(@user.member_id)
			# advance = @payment.money
       
	  #       @member.member_lv_id = @user.apply_type
	        
	  #       @adv_log ||= Logger.new('log/adv.log')
	  #         @adv_log.info("member id: "+@member.member_id.to_s+"--advance:"+@member.advance.to_s+"=>"+ advance.to_s)
	  #         @member.advance += advance
	  #       @member.save
			redirect_to topup_cards_path(amount: @payment.money )
		end
	end

	def notify
		ModecPay.logger.info "[#{Time.now}][#{request.remote_ip}] #{request.request_method} \"#{request.fullpath}\" params : #{ params.to_s }"

		return render :text=>params[:payment_id]

		@payment = Payment.find(params.delete(:payment_id))

		return render :nothing=>true, :status=>:forbidden if @payment.paid?

		adapter  = params.delete(:adapter)
		params.delete :controller
		params.delete :action

		

		@order = @payment.pay_bill.order
		@user = @payment.user


		result = ModecPay.verify_notify(adapter,params,{ :bill99_redirect_url=>"#{site}/#{order_path(@order)}",:ip=>request.remote_ip })

		@payment.payment_log.update_attributes({:notify_ip=>request.remote_ip,
                                               :notify_params=> params.to_json,
                                               :notified_at=>Time.now,
                                               :result=>result.to_json}) if @payment.payment_log

		if result.is_a?(Hash) && result.present?
			response = result.delete(:response)
			if result.delete(:payment_id) == @payment.payment_id.to_s && !@payment.paid?
				@payment.update_attributes(result)
				@order.update_attributes(:pay_status=>'1')
				OrderLog.new do |order_log|
					order_log.rel_id = @order.order_id
					order_log.op_id = @user.member_id
					order_log.op_name = @user.login_name
					order_log.alttime = @payment.t_payed
					order_log.behavior = 'payments'
					order_log.result = "SUCCESS"
					order_log.log_text = "订单支付成功！"
				end.save
			end
			if @payment.pay_bill.bill_type =='payments' && @payment.pay_bill.pay_object == 'order'
				redirect_to detail_order_path(@payment.pay_bill.order)
			else
				@member = Member.find(@user.member_id)
				advance = @payment.money
	       
		        @member.member_lv_id = @user.apply_type
		        
		        @adv_log ||= Logger.new('log/adv.log')
		          @adv_log.info("member id: "+@member.member_id.to_s+"--advance:"+@member.advance.to_s+"=>"+ advance.to_s)
		          @member.advance = advance
		        @member.save
				redirect_to member_path
			end
		else
			response =  result
		end

		render :text=>response
	end

	def test_notify		

		@payment = Payment.find(params[:id])
		if @payment #&& @payment.status == 'ready'
			adapter = @payment.pay_app_id
			order_id = @payment.pay_bill.rel_id

			@modec_pay = ModecPay.new adapter do |pay|
				pay.action = "/payments/#{@payment.payment_id}/#{adapter}/notify"
				pay.method = "post"

				pay.fields = {}

				time = Time.now
       
				if adapter == "alipay"
					# ===Alipay
					pay.fields["discount"] = "0.00"
					pay.fields["payment_type"] = "1"
					pay.fields["subject"] = "昌麒订单(#{order_id})"
					pay.fields["trade_no"] = "2013091823959388"
					pay.fields["buyer_email"] = "596849181@qq.com"
					pay.fields["gmt_create"] = "2013-08-14 19:08:03"
					pay.fields["notify_type"] = "trade_status_sync"
					pay.fields["quantity"] = "1"
					pay.fields["out_trade_no"] = @payment.payment_id
					pay.fields["seller_id"] = "2088701875473608"
					pay.fields["notify_time"] = time.strftime("%Y-%m-%d %H:%M:%S")
					pay.fields["trade_status"] = "TRADE_SUCCESS"
					pay.fields["is_total_fee_adjust"] = "N"
					pay.fields["total_fee"] = @payment.cur_money.round(2)
					pay.fields["gmt_payment"] = (time - 30.seconds).strftime("%Y-%m-%d %H:%M:%S")
					pay.fields["seller_email"] = "eileen.gu@CQ.com"
					pay.fields["price"] = @payment.cur_money.round(2)
					pay.fields["buyer_id"] = "2088102350773884"
					pay.fields["notify_id"] = "1b2658003817950ee56fb6785ce505086w"
					pay.fields["use_coupon"] = "N"
					pay.fields["sign_type"] = "MD5"
				end				
			end

			render :inline=>@modec_pay.html_form
		else
			render :text=>"alreay paid"
		end
	end

	private
	def payment_params
		params.require(:payment).permit(:part_pay,:pay_app_id)
	end

end
