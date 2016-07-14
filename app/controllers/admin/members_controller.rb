# encoding:utf-8
require 'ya2yaml'
require 'sms'

module Admin
    class MembersController < Admin::BaseController
      
      def index
        @total_member = Member.count()
        
        @members = Member.paginate(:page => params[:page], :per_page => 20).order("member_id DESC")
        

        @column_data = YAML.load(File.open(Rails.root.to_s+"/config/columns/member.yml"))

        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @members }
        end
      end

      def show
      end

      def edit
        @member = Member.find(params[:id])
      end

      def updateInfo
        @member = Member.find(params[:id])
        @member.update_attributes(params[:member])
        
        # @member.mobile = params[:member][:mobile]
        # @member.email = params[:member][:email]
        # @member.member_lv_id = params[:member][:member_lv_id]
        if @member.advance != params[:member][:advance].to_i
          @adv_log ||= Logger.new('log/adv.log')
          @adv_log.info("member id: "+@member.member_id.to_s+"--advance:"+@member.advance.to_s+"=>"+params[:member][:advance])
          # @member.advance = params[:member][:advance]
        end
        # @member.save
        redirect_to admin_members_path
      end

      def info
        @member = Member.find(params[:id])
      end

      def send_sms
          if  params[:send_all] == "1"
              tels =  Member.all.select { |u| u.mobile.present?&&(/^[1-9][0-9]{10}$/ =~ u.mobile) }.collect{|x| x.mobile}
          else
              tels = params[:tels]
          end

          text = params[:member][:text]


          if text.blank?
              render :js=>"alert('短信内容不能为空');"
              return
          end

          @sms_log ||= Logger.new('log/sms.log')
          begin
             while tels.size > 20 do
                 sends = tels.slice!(0,20).join(";")
                 if Sms.send(sends,text)
                    @sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{sends}]短信群发:#{text}")
                 end
             end
             if tels.size > 0
                sends = tels.slice!(0,20).join(";")
                if Sms.send(sends,text)
                  @sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{sends}]短信群发:#{text}")
                end
             end
          rescue

          end

        respond_to do |format|
          format.js
        end

      end


      def send_sms2
        tels = params[:member][:mobiles]
        text = params[:member][:text]

        if tels.blank?
              render :js=>"alert('请填写手机号码');"
              return
        end


        if text.blank?
              render :js=>"alert('短信内容不能为空');"
              return
        end
        @sms_log ||= Logger.new('log/sms.log')

        begin
          tels = tels.split(";").select{|x| x.present?&&(/^[1-9][0-9]{10}$/ =~ x)}.join(";")
          if Sms.send(tels,text)
              @sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{tels}]短信群发:#{text}")
          end
        rescue Exception => e
              @sms_log.info("[#{current_admin.login_name}][#{Time.now}]错误:#{e}")
        end

        respond_to do |format|
          format.js
        end

      end

      def columns
        
      end

      def export

          #orders = Order.all
   
      #    package = Axlsx::Package.new
        #  workbook = package.workbook

    #        workbook.styles do |s|


         # workbook.add_worksheet(:name => "ordersinfo") do |sheet|

     #     sheet.add_row [" 订单号","会员","收货人","下单时间","订单状态","付款状态","发货状态","订单金额","店铺id","收货地址","运单号"]
        #             

         #   row_count=0

        #    orders.each do |order| 
          #    orderid=order.order_id.to_s + " "
            #  memberid=order.member_id
           #   shipname=order.ship_name
            #  createdat=order.created_at
            #  statustext=order.status_text
          #    paystatustext=order.pay_status_text
           #   shipstatustext=order.ship_status_text
          #    finalamount=order.final_amount
           
           #  shipaddrs=order.ship_addr
          
        #      sheet.add_row [orderid,memberid,shipname,createdat,statustext,paystatustext,shipstatustext,finalamount,nil,shipaddrs]
       #       row_count +=1
        #    end
        #   end
        #  send_data package.to_stream.read,:filename=>"  order_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xlsx"
       #   end
  # end


       members = Member.all
       package = Axlsx::Package.new
          workbook = package.workbook

           workbook.styles do |s|


         workbook.add_worksheet(:name => "members") do |sheet|

          sheet.add_row ["会员ID ","会员名","姓名","会员等级","手机","身份证"," 会员卡提现"]
                     

            row_count=0

            members.each do |member|
              nober=member.member_id.to_s + " "
              cardvalue=member.account.login_name
              cardtype=member.name
              salestatus=member.member_lv_id
              usestatus=member.mobile
              cardstatus=member.id_card_number
             usephoto =member.point
              sheet.add_row [nober,cardvalue,cardtype,salestatus,usestatus,cardstatus,usephoto]
              row_count +=1
            end
           end
          send_data package.to_stream.read,:filename=>"member_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xlsx"
          end
      end

      def column_reload
         begin
            @column_data_member = YAML.load(File.open(Rails.root.to_s+"/config/columns/member.yml"))
            @column_data_member[params[:column_id]][2] = params[:col_stat]
            @yaml = @column_data_member
            File.open(Rails.root.to_s+"/config/columns/member.yml", 'w'){|f| 
              f.puts @column_data_member.ya2yaml
            }
         rescue => err 
           logger = Logger.new(Rails.root.to_s + '/log/err.log')  
           logger.error err  
           logger.close       
         end
         # @result = true
         respond_to do |format|
            format.json { render json: {success: true} }
         end
      end

      def new
      end

    end
    
end
