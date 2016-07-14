#encoding:utf-8
class Admin::OrdersController < Admin::BaseController
	before_filter :get_return_url, :only=>[:show,:detail,:pay,:delivery,:reship,:refund]
	skip_before_filter :verify_authenticity_token,:only=>[:batch]

	before_action :set_order, except: [:index,:batch,:downorder]

	def destroy
	    id = params[:id]
	    @order_log = OrderLog.where(:rel_id=>id)
	    @order_log.destroy_all
	    @order_item = OrderItem.where(:order_id=>id)
	    @order_item.destroy_all
	    @order.destroy

	    respond_to do |format|
	      format.html { redirect_to admin_orders_url }
	      format.json { head :no_content }
	      format.js
	    end
	end

	def index
		if params[:status].nil?
			@orders_nw = Order.order("createtime desc")
		elsif
			@orders_nw = Order.where(:status=>params[:status]).order("createtime desc")
		end

		if !params[:pay_status].nil?
			@orders_nw = @orders_nw.where(:pay_status=>params[:pay_status])
		end

		if !params[:ship_status].nil?
			@orders_nw = @orders_nw.where(:ship_status=>params[:ship_status])
    	end

		@order_ids = @orders_nw.pluck(:order_id)
	    role=current_admin.login_name.split( "_")[0]

    	@orders = @orders_nw.includes(:user).paginate(:page=>params[:page],:per_page=>30)
		respond_to do |format|
			format.js
			format.html
		end
	end
	
    def export    	
  		orders = Order.all
   
          package = Axlsx::Package.new
          workbook = package.workbook

            workbook.styles do |s|


          workbook.add_worksheet(:name => "ordersinfo") do |sheet|

          sheet.add_row [" 订单号","会员","收货人","下单时间","订单状态","付款状态","发货状态","订单金额","店铺id","收货地址","运单号"]
                     

            row_count=0

            orders.each do |order| 
              orderid=order.order_id.to_s + " "
              memberid=order.member_id
              shipname=order.ship_name
              createdat=order.created_at
              statustext=order.status_text
              paystatustext=order.pay_status_text
              shipstatustext=order.ship_status_text
              finalamount=order.final_amount
           
             shipaddrs=order.ship_addr
          
              sheet.add_row [orderid,memberid,shipname,createdat,statustext,paystatustext,shipstatustext,finalamount,nil,shipaddrs]
              row_count +=1
            end
           end
          send_data package.to_stream.read,:filename=>"order_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xlsx"
          end
    end


	def search
		if params[:s] && params[:s][:q].present?
			key = params[:s][:q]

			@orders = Order.includes(:user).where("order_id like ? or ship_name like ?","%#{key}%","%#{key}%").order("order_id desc")
			@order_ids = @orders.pluck(:order_id)
			@orders = @orders.paginate(:page=>params[:page],:per_page=>30)
			render :index
		else
			redirect_to admin_orders_url
		end
	end

	def batch
		act = params[:act]
              order_ids =  params[:order_ids] || []
              conditions = { :order_id=>order_ids }

              if act == "export"
              	orders = Order.where(conditions)
	              Order.export(orders)
	              return render :json=>{:csv=>"/tmp/orders.csv"}
              end

              if act == "tag"
              	tegs = params[:tegs] || {}

	              tegs.values.each  do |teg|
	                    	if teg[:technicals] == "checked"
	                    		Tagable.where(:rel_id=>order_ids,:tag_type=>"orders",:tag_id=>teg[:tag_id]).delete_all if teg[:state] == "none"
	                    	end

	                    	if teg[:technicals] == "uncheck"
	                    		order_ids.each do |order_id|
	                    			Tagable.create(:rel_id=>order_id,:tag_id=>teg[:tag_id],:tag_type=>"orders",:app_id=>"b2c")
	                    		end
	                    	end

	                    	if teg[:technicals] == "partcheck"
	                    		if teg[:state] == "all"
	                    			order_ids.each do |order_id|
				                     tagable = Tagable.where(:rel_id=>order_id,:tag_id=>teg[:tag_id],:tag_type=>"orders").first_or_initialize(:app_id=>"b2c")
				                     tagable.save
			                     end
	                    		end

	                    		if teg[:state] == "none"
	                    			Tagable.where(:rel_id=>order_ids,:tag_type=>"orders",:tag_id=>teg[:tag_id]).delete_all
	                    		end
	                    	end
	              end
              end


		if act == "get_same_tags"

			tag_ids = Tagable.where(:rel_id=>order_ids,:tag_type=>"orders").pluck(:tag_id)

			hash = Hash.new(0)
			tag_ids.each do |id|
			    if hash[id]
			        hash[id] += 1
			    else
			        hash[id] = 1
			    end
			end
			stat = Hash.new

			hash.each do |tag_id,count|
				if count>0 && count == order_ids.size
					stat[tag_id] = "all"
				end

				if count > 0 && count < order_ids.size
					stat[tag_id] = "part"
				end

				if count == 0
					stat[tag_id] = "none"
				end
			end
			return render :json=>stat
		end

              render :nothing=>true
	end

	def show () end

	def detail () end

	def pay () end

	def dopay
		# return render :js=>"alert('获取订单失败');" unless @order

		if @order.pay_status == '1'
			return render :text=>"该订单已付款 !",:layout=>"admin"
		end

		@user = @order.user

		pay_app_id = params[:payment][:pay_app_id]
		params[:payment].merge! Payment::PAYMENTS[pay_app_id.to_sym]

		@payment = Payment.new params[:payment]  do |payment|
			payment.payment_id = Payment.generate_payment_id

			payment.status = 'ready'
			payment.pay_ver = '1.0'
			payment.paycost = 0

			payment.account = '昌麒投资'
			payment.member_id = payment.op_id = @user.member_id
			payment.pay_account = @user.login_name
			payment.ip = request.remote_ip
			payment.t_begin = payment.t_confirm = Time.now.to_i
			payment.cur_money = params[:payment][:money].to_i
			payment.status = 'succ'
			payment.t_payed = Time.now.to_i

			payment.pay_bill = Bill.new do |bill|
				bill.rel_id  = @order.order_id
				bill.bill_type = "payments"
				bill.pay_object  = "order"
				bill.money = payment.money
			end
		end


		if @payment.save
			@order.update_attributes(:pay_status=>'1')

			OrderLog.new do |order_log|
				order_log.rel_id = @order.order_id
				order_log.op_id = current_admin.account_id
				order_log.op_name = current_admin.login_name
				order_log.alttime = @payment.t_payed
				order_log.behavior = 'payments'
				order_log.result = "SUCCESS"
				order_log.log_text = "订单支付成功！"
			end.save

			return_url =  params[:return_url] || admin_orders_url
			redirect_to "#{return_url}##{@order.order_id}"
		else
			render :pay
		end

	end

	def delivery
		@delivery = Delivery.new do |delivery|
			delivery.ship_name = @order.ship_name
			delivery.ship_tel = @order.ship_tel
			delivery.ship_mobile = @order.ship_mobile
			delivery.ship_area = @order.ship_area
			delivery.ship_addr = @order.ship_addr
			delivery.ship_zip = @order.ship_zip
		end
	end

	def dodelivery
		if @order.ship_status == '1'
			return render :text=>"该订单已发货 !",:layout=>"admin"
		end

		@delivery = Delivery.new delivery_params do |delivery|
			delivery.t_begin = Time.now.to_i
			delivery.status = "succ"
		end
		if @delivery.save
			# begin
			# return render text: @delivery.delivery_items.to_json
			 @orderItems =  OrderItem.where(order_id: @delivery.order_id)
				@orderItems.each do |dly_item|
					# update order_item send_num
					order_item = OrderItem.find_by_item_id(dly_item.item_id)
					order_item.update_attribute :sendnum, order_item.sendnum.to_i + dly_item.nums if order_item

					# update product store
					product = order_item.product
					if product
						product.update_attribute :freez, (product.freez.to_i + dly_item.nums)
						product.update_attribute :store, (product.store.to_i - dly_item.nums)
					end
					goods = order_item.good
					if goods
						goods.update_attribute :store, (goods.store.to_i - dly_item.nums)
					end
				end

				#  update order ship_status
				dly_ids = Delivery.where(:order_id=>@delivery.order_id).pluck(:delivery_id)
				send_total = DeliveryItem.where(:delivery_id=>dly_ids).sum("number")

				order_total = OrderItem.where(:order_id=>@delivery.order_id).sum("nums")

				op = Account.find_by_login_name(@delivery.op_name)
				order_log = OrderLog.new do |order_log|
					order_log.rel_id = @delivery.order_id
					order_log.op_id = op.account_id
					order_log.op_name = @delivery.op_name
					order_log.alttime = @delivery.t_begin
					order_log.behavior = 'delivery'
					order_log.result = "SUCCESS"
				end

		
					@delivery.order.update_attribute :ship_status, '1'
					order_log.log_text = {:txt_key=>"商品已发货 ! ",:delivery_id=>@delivery.delivery_id}.serialize
					order_log.save
				
				text = "您的订单#{@order.order_id}已发货,使用#{@delivery.logi_name},单号为#{@delivery.logi_no}.请注意查收! [昌麒]"
				#调用微信通知

				# tel  =@delivery.ship_mobile
				# Sms.send(tel,text)
			#rescue Exception => e
			# end
			return_url =  params[:return_url] || admin_orders_url
			redirect_to "#{return_url}##{@order.order_id}"
		else
			render :delivery
		end
	end


	def reship
		@reship = Reship.new do |reship|
			reship.ship_name = @order.ship_name
			reship.ship_tel = @order.ship_tel
			reship.ship_mobile = @order.ship_mobile
			reship.ship_area = @order.ship_area
			reship.ship_addr = @order.ship_addr
			reship.ship_zip = @order.ship_zip
		end
	end

	def doreship

		if ['0','4'].include?(@order.ship_status)
			return render :text=>"该订单#{order.ship_status_text}",:layout=>"admin"
		end

		@reship = Reship.new params[:reship] do |reship|
			reship.t_begin = Time.now.to_i
			reship.status = "succ"
		end
		if @reship.save

			return_url =  params[:return_url] || admin_orders_url
			redirect_to "#{return_url}##{@order.order_id}"
		else
			render :reship
		end
	end

	def refund () end

	def dorefund

		if @order.pay_status == "5"
			return render :text=>"该订单已退款 !",:layout=>"admin"
		end

		@refund = Refund.new params[:refund]  do |refund|
			refund.refund_id = Refund.generate_refund_id
			refund.pay_ver = '1.0'
			refund.currency = "CNY"
			refund.paycost = 0
			refund.t_begin = refund.t_confirm = Time.now.to_i
			refund.cur_money = params[:refund][:money].to_i
			refund.status = 'succ'
			refund.t_payed = Time.now.to_i

			refund.bill = Bill.new do |bill|
				bill.rel_id  = @order.order_id
				bill.bill_type = "refunds"
				bill.pay_object  = "order"
				bill.money = refund.money
			end
		end


		if @refund.save
			#部分退款
			if @refund.money > 0 && @order.refunded_amount < @order.paid_amount
				@order.update_attributes(:pay_status=>'4')
				txt_key = "订单部分退款 ! "
			else
				@order.update_attributes(:pay_status=>'5')
				txt_key = "订单已退款 ! "
			end

			OrderLog.new do |order_log|
				order_log.rel_id = @order.order_id
				order_log.op_id = current_admin.account_id
				order_log.op_name = current_admin.login_name
				order_log.alttime = @refund.t_payed
				order_log.behavior = 'refunds'
				order_log.result = "SUCCESS"
				order_log.log_text = {:txt_key=>txt_key, :refund_id=>@refund.refund_id}.serialize
			end.save

			return_url =  params[:return_url] || admin_orders_url
			redirect_to "#{return_url}##{@order.order_id}"
		else
			render :refund
		end
	end

	def update
		@order.update_attributes(order_params)

		if @order.status == 'finish'
			order_log = OrderLog.new do |order_log|
	                order_log.rel_id = @order.order_id
	                order_log.op_id = current_admin.account_id
	                order_log.op_name = current_admin.login_name
	                order_log.alttime = Time.now.to_i
	                order_log.behavior = 'finish'
	                order_log.result = "SUCCESS"
	                order_log.log_text = "订单完成 !"
	             end.save
	      end

	      if @order.status == 'dead'
			order_log = OrderLog.new do |order_log|
	                order_log.rel_id = @order.order_id
	                order_log.op_id = current_admin.account_id
	                order_log.op_name = current_admin.login_name
	                order_log.alttime = Time.now.to_i
	                order_log.behavior = 'cancel'
	                order_log.result = "SUCCESS"
	                order_log.log_text = "取消订单 !"
	             end.save
	      end

		respond_to do |format|
			format.html
			format.js
		end
	end

	def comment ()  end

    def update_memo    	
    	@order.memo = params[:order][:memo]
    	@order.save
    	order_log = OrderLog.new do |order_log|
	                order_log.rel_id = @order.order_id
	                order_log.op_id = current_admin.account_id
	                order_log.op_name = current_admin.login_name
	                order_log.alttime = Time.now.to_i
	                order_log.behavior = "memo"
	                order_log.result = "SUCCESS"
	                order_log.log_text = "memo info:#{params[:order][:memo]}"
	             end.save
    	redirect_to admin_orders_url
    end

	# 购物单
	def print_order
		@title = "购物单"
		@order = Order.includes(:order_items).find_by_order_id(params[:id])
		render :layout=>"print"
	end

	# 配货单
	def print_preparer
		@title = "配货单"
		@order = Order.includes(:order_items).find_by_order_id(params[:id])
		render :layout=>"print"
	end

	private

	def set_order
		@order = Order.find(params[:id])
	end

	def order_params
		params.require(:order).permit(:status,:id)
	end

	def delivery_params
		params.require(:delivery).permit(:order_id,:member_id,:op_name, :delivery,:logi_id,:logi_name,:logi_no,
 										 :money, :is_protect,:province,:city,:district,:ship_zip,:ship_name,:ship_mobile,
 										:ship_addr, :ship_tel, :memo, 
 										delivery_items_attributes:[:order_item_id,:item_type,:product_id,:prouct_bn,:product_name,:number])
	end

	def get_return_url
		@return_url = request.env["HTTP_REFERER"] || admin_orders_url(:page=>params[:page])
	end

	# def deal_with_participant_notify(data)
	#     groupbuy_id, participant_id, user_id = data['attach'].split('_')
	#     participant = Participant.find_by(id: participant_id)
	#     if participant.try(:pay_notify_status) == 0
	#       parent = participant.event_id.present? ? 'events' : 'groupbuys'
	#       participant.update_column(:status_pay, 1)
	#       # 模板消息
	#       openid = data['openid']
	#       url = '/' + parent + '/groupbuy_id'
	#       title = participant.event_id.present? ? Event.find_by(id: groupbuy_id).en_title : Groupbuy.find_by(id: groupbuy_id).en_title
	#       data = {
	#         first: { value: 'Paid successfully(支付成功)', color: '#173177' },
	#         orderMoneySum: { value: format('%.2f', (data['cash_fee'].to_f / 100.00).to_s), color: '#173177' },
	#         orderProductName: { value: title, color: '#173177' },
	#         remark: { value: 'Paid successfully and please check for more information in Groupmall!(您已支付成功！您可以在吃货帮查看更多详情!)', color: '#173177' }
	#       }
	#       res_data = send_template_info_api openid, data, url
	#       Rails.logger.info "##########################res_data=#{res_data}"

	#       # 发送至boss
	#       nickname = User.find_by(id: user_id).nickname
	#       info = "#{nickname}刚刚完成了一笔支付：#{title}, 赶紧去看看哦～"
	#       send_info_preview_api info
	#     end
	# end

	# def send_info_preview_api info
	#   post_url = "https://api.weixin.qq.com/cgi-bin/message/mass/preview?access_token=#{get_jsapi_access_token}"
	#   openid = 'oxKrEuBgzuxUBJzZghogSkygibSw'
	#   data = {touser: openid, text: {content: info}, msgtype: 'text'}.to_json
	#   RestClient.post post_url, data
	# end

	# def send_template_info_api openid, data, url = '', template_id = 'M9Mf27pbdTdTIxN_AfwbI3G_9mb5FlaydtsKwOZgSX4'
	#   post_url = "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=#{get_jsapi_access_token}"
	#   post_data = {touser: openid, template_id: template_id, data: data, url: url}.to_json
	#   Rails.logger.info post_data
	#   RestClient.post post_url, post_data
	# end

	# def get_jsapi_ticket
	#   wechat = Wechat.first
	#   return wechat.jsapi_ticket if wechat.jsapi_ticket_expires_at.to_i > Time.now.to_i && wechat.jsapi_ticket.present?
	#   access_token = get_jsapi_access_token
	#   get_url = 'https://api.weixin.qq.com/cgi-bin/ticket/getticket'
	#   res_data_json = RestClient.get get_url, {:params => {:access_token => access_token, :type => 'jsapi'}}
	#   res_data_hash = ActiveSupport::JSON.decode res_data_json
	#   if res_data_hash['errmsg'] == 'ok'
	#     jsapi_ticket = res_data_hash['ticket']
	#     jsapi_ticket_expires_at = Time.zone.now.to_i + res_data_hash['expires_in'].to_i
	#     wechat.update_attributes(:jsapi_ticket => jsapi_ticket, jsapi_ticket_expires_at: jsapi_ticket_expires_at)
	#   end
	#   jsapi_ticket
	# end

	# def get_jsapi_access_token
	#   wechat = Wechat.first
	#   return wechat.access_token if wechat.access_token_expires_at.to_i > Time.now.to_i
	#   get_url = 'https://api.weixin.qq.com/cgi-bin/token'
	#   res_data_json = RestClient.get get_url, {:params => {:appid => WX_APP_ID, :grant_type => 'client_credential', :secret => WX_APP_SECRET}}
	#   res_data_hash = ActiveSupport::JSON.decode res_data_json
	#   access_token = res_data_hash["access_token"]
	#   expires_at = Time.now.to_i + res_data_hash['expires_in'].to_i
	#   wechat.update_attributes(:access_token => access_token, :access_token_expires_at => expires_at)
	#   access_token
	# end

	# def deal_with_downpayment_notify(data)
	#     wishlist_id, user_id = data['attach'].split('_')
	#     total_fee = (data['total_fee'].to_f / 100).to_f
	#     downpayment = Downpayment.create(user_id: user_id, wishlist_id: wishlist_id, price: total_fee)
	#     # 模板消息
	#     title = 'Downpayment / 定金'
	#     remark = 'Your downpayment number is(您的定金编号为):' + downpayment.id.to_s
	#     data = {
	#       first: { value: '支付成功', color: '#173177' },
	#       orderMoneySum: { value: data['cash_fee'].to_f / 100.00, color: '#173177' },
	#       orderProductName: { value: title, color: '#173177' },
	#       remark: { value: remark, color: '#173177' }
	#     }
	#     send_template_info_api data['openid'], data

	#     # 发送至boss
	#     nickname = User.find_by(id: user_id).nickname
	#     info = "#{nickname}刚刚支付了一笔定金，共计#{total_fee}元。"
	#     send_info_preview_api info
	#   end
	# end


	# def send_weixin_notice

	# end

	

end
