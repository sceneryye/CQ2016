#encoding:utf-8
require "iconv"
require 'axlsx'
require 'csv'
require 'allinpay'
class Admin::CardsController < Admin::BaseController
  skip_before_filter :verify_authenticity_token,:only=>[:batch]
  include Admin::CardsHelper  
  include Allinpay

  before_filter :require_permission!

  before_action :set_card, except: [:index,:export]

  def trading_log
    @log = CardTrading.order("id ASC")
    if params[:card_no]
      @log =@log.where(card_no: params[:card_no])
    end
    @log = @log.paginate(:page=>params[:page],:per_page=>20)
  end
  
  def allinpay () end

  def index
    if params[:card_type]=='B'
      @card_type = 'B'
      @tb = 'disabled'
    else
      @card_type='A'
      @ta = 'disabled'
    end

    case params[:status]
    when '未使用'
      @s0 = 'disabled'
    when '未激活'
      @s1 = 'disabled'
    when '已使用'
      @s2 = 'disabled'
    when '冻结'
      @s3 = 'disabled'
    when '挂失'
      @s4 = 'disabled'
    end 

    @labels = Label.all

    sale_status = params[:sold] == "0" ? false : true
    @key = params[:search][:key] if params[:search]

    @cards = Card.where(card_type: @card_type).order("no ASC")

    if params[:status].present?
        @cards = @cards.where(status: params[:status])
    end

    if @key.present?
        @cards = Card.where("no like :key",:key=>"%#{@key}%")
    end

    if params[:parent_id].present?
        @cards = Card.where(parent_id: params[:parent_id])
    end


    @cards = @cards.paginate(:page=>params[:page],:per_page=>20)
    @cards_total = Card.count

  end

  def show ()  end

 
  def edit 

    @parents = Card.where('card_type=? and status<>? ','A','未使用' )

  end


  def update

    if @card.update_attributes(card_params)

      message = params[:card].collect  do |key,value|
          I18n.t("card.#{key}") + "=" + value
      end.join(",")

      CardLog.create(:member_id=>current_admin.account_id,
                                              :card_id=>@card.id,
                                              :message=>"更新卡信息,#{message}")
      redirect_to admin_cards_path(card_type:@card.card_type), notice: 'Card was successfully updated.'

     
    
    else
      render action: "edit" 
    end
  end


  def buy () end

  def use () end

  def edit_user 
      @member_card = @card.member_card
      @buyer =  @member_card.buyer
  end
  
  def edit_pay
      @card = Card.find(params[:id])
      @user_card = @member_card = @card.member_card
  end

  def logs
      @card = Card.find(params[:id])
      @logs = @card.card_logs
  end

  def tag

      if params[:cards] == "all"
          @cards = Card.all
      else
          @cards = Card.find(params[:cards])
      end
      @cards.each do |card|
         Labelable.where(:label_id=>params[:label],
                         :labelable_id=>card.id,
                         :labelable_type=>"Card").first_or_create if card
      end

      render :text=>"ok"
  end

  def untag
      @card = Card.find(params[:id])
      @card.labelables.where(:label_id=>params[:label]).delete_all
      render "untag"
  end

  def cancel_order
     @card = Card.find(params[:id])
     @card.update_attribute :sale_status,false
     @member_card = @card.member_card
     CardLog.create(:member_id=>current_admin.account_id,
                    :card_id=>@card.id,
                    :message=>"取消卡订单,购买者=#{@member_card.buyer.login_name}")
     @member_card.destroy
     redirect_to admin_cards_url
  end

   def export

      cards = Card.all
      package = Axlsx::Package.new
          workbook = package.workbook

            workbook.styles do |s|

          workbook.add_worksheet(:name => "ordersinfo") do |sheet|

          sheet.add_row ["卡号","面值","类型","销售状态","使用状态","卡状态","使用人手机","银行","银行卡号"]
                     

            row_count=0

            cards.each do |card| 

              nober=card.no + " "
              cardvalue=card.value
              cardtype="[#{level(card.card_type)}]" if level(card.card_type)
              salestatus=card.sale_status ? "已出售" : "未出售"
              usestatus=card.use_status ?  "已使用" : "未使用"
              cardstatus=card.status 
              usephoto = card.member_card&&card.member_card.user_tel.present? ? card.member_card.user_tel : "未登记"
              bankname = card.member_card.bank_name if !card.member_card.nil?
              cbankmenber = card.member_card.bank_card_no if !card.member_card.nil?

              sheet.add_row [nober,cardvalue,cardtype,salestatus,usestatus,cardstatus,usephoto,bankname,cbankmenber]
              row_count +=1
            end
           end
          send_data package.to_stream.read,:filename=>"card_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xlsx"
          end
    
       end
   
  def import(options={:encoding=>"GB18030:UTF-8"})
        file = params[:card][:file].tempfile
        book = Spreadsheet.open(file)
        pp "starting import ..."
        sheet = book.worksheet(0)

        @card = Card.new
    
        sheet.each_with_index do |row,i|
           
            if i >= 0
              @card = Card.new
              @card_no = Card.find_by_no(row[0].strip)
         
                   if @card_no&&@card_no.persisted?
                        @card = @card_no
                    else
                      
                        @card.no = row[0]
                   end 
                     @card.password=row[1]
                     @card.card_type=row[2]
                     @card.save!

             end
         end
        redirect_to admin_cards_path
  end

  def active
    type = '1'
    res_data = ActiveSupport::JSON.decode card_active(@card.no, type)
    save_log res_data,@card.no,'active'
    @card.update_attributes(status: '未激活')
    # render json: {data: res_data}
    redirect_to admin_cards_path(card_type:@card.card_type,status:@card.status)
  end

  def topup
    card_id = @card.no
    amount = ((params[:amount].to_f)*100).to_i
    opr_id = '0229000040'
    desn = params[:desn]
    res_data = ActiveSupport::JSON.decode topup_single_card(card_id, amount,opr_id, desn)
    save_log res_data,card_id,'topup'

    redirect_to admin_cards_path(card_type:@card.card_type,status:@card.status),notice:"已经成功充值,卡内余额：#{res_data["ppcs_cardsingletopup_add_response"]["result_info"]["account_balance"].to_f/100}"
    #{"data":{"ppcs_cardsingletopup_add_response":{"res_timestamp":20160623112400,"res_sign":"C183F86B62979D238A471C4310A745B0","trans_no":"0116856621","result_info":{"amount":1000,"prdt_no":"0002","validity_date":20460521,"top_up_way":1,"valid_balance":2560200,"card_id":8661089811000000016,"account_balance":2560200,"desn":""},"order_id":"999990053990001_146665223742"}}}
  end

  def pay_with_pwd
    amount = params[:amount]
    card_id = @card.no
    password = params[:password]
    res_data = ActiveSupport::JSON.decode pay_with_password(amount, card_id, password)
    save_log res_data,card_id,'pay_with_pwd'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def reset_password
    card_id = @card.no
    password = @card.password
    res_data = ActiveSupport::JSON.decode card_reset_password(card_id, password)
    save_log res_data,card_id,'reset_password'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def card_status
    status = params[:status]
    card_id = @card.no
    reason = params[:reason]
    id_type = '1' #证件类型：身份证
    id_no = @card.member_card.user.id_card_number if @card.member_card
    data =  case status
            when 'freeze'
              card_freeze(card_id, reason)
            when 'unfreeze'
              card_unfreeze(card_id, reason)
            when 'report_loss'
              card_report_loss(card_id, id_no, id_type, reason)
            when 'cancel_loss'
              card_cancel_loss(card_id, id_no, id_type, reason)
            end

    res_data = ActiveSupport::JSON.decode data
    save_log res_data, card_id, status

    if res_data["error_response"].blank?
        case status
        when 'report_loss'
          @card.update_attribute :status, '挂失'
        when 'cancel_loss'
          @card.update_attribute :status, '已使用'
        when 'freeze'
          @card.update_attribute :status, '冻结'
        when 'unfreeze'
          @card.update_attribute :status, '已使用'
        end
        notice =  "卡号：#{@card.no}已经成功#{@card.status}"
      else
        notice = "操作未成功"
      end
    redirect_to admin_cards_path(card_type:@card.card_type,status:@card.status),notice: notice
  end

  def get_info
    card_id = @card.no
    password = params[:password]
    res_data = ActiveSupport::JSON.decode card_get_info(card_id, password)
    save_log res_data,card_id,'get_info'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def get_trade_log
    begin_date = params[:begin_date]
    end_date = params[:end_date]
    card_id = @card.no
    password = params[:password]
    page_no = params[:page_no]
    page_size = params[:page_size]
    card_id = '8661089811000000016'
    password = '123456'
    begin_date = "20160426"
    end_date = "20160525"
    page_no = '1'
    page_size = '20'

    # return render json: {data: {error_message: '不能查询90天之前的记录！'}} if Time.parse(begin_date) < (Time.now - 3600 * 24 * 90)
    res_data = ActiveSupport::JSON.decode card_get_trade_log(begin_date, end_date, card_id, password, page_no, page_size)
    save_log res_data,card_id,'get_trade_log'
    # #{"ppcs_txnlog_search_response":{"res_timestamp":20160524143412,"res_sign":"A14A04EA740BE02FCE70469A38DD55D0",
    # # "total":2,
    # # "txn_log_arrays":{"txn_log":[
    # #   {"prdt_no":"行业预付卡",
    # #   "int_txn_dt":20160524,"txn_cd":"B0020",
    # #   "acct_bal_at":79400,"brand_id":"0001",
    # #   "term_id":"        ",
    # #   "access_ref_seq_id":"20160524144051_68",
    # #   "avail_bal_at":79400,"card_id":8661089810000000042,
    # #   "int_txn_tm":143402,"txn_sta_cd":2,"txn_fee_at":0,
    # #   "accept_brh_id":"昌麒投资有限公司","open_brh_id":"0233103005","int_txn_seq_id":"0111445788","txn_at":10700},

    # #   {"prdt_no":"行业预付卡","int_txn_dt":20160524,"txn_cd":"B0020","acct_bal_at":90100,"brand_id":"0001","term_id":"        ",
    # #     "access_ref_seq_id":"20160524144191_50","avail_bal_at":90100,"card_id":8661089810000000042,
    # #     "int_txn_tm":142824,"txn_sta_cd":2,"txn_fee_at":0,
    # # "accept_brh_id":"昌麒投资有限公司","open_brh_id":"0233103005","int_txn_seq_id":"0111444850","txn_at":9900}]}}}
    # if res_data["ppcs_txnlog_search_response"]
    #   txn = res_data["ppcs_txnlog_search_response"]["txn_log_arrays"]["txn_log"]
     
    #   txn.each do |txn|
    #     # @txnlog = CardAllinpayTxnlog.find(txn["int_txn_seq_id"].to_i)

    #     # if @txnlog.new_record?
    #       txn.delete!(:prdt_no)
    #       txn.delete!(:accept_brh_id)
    #       @txnlog = CardAllinpayTxnlog.new txn
    #       @txnlog.save!
    #     # end
    #   end      
    # end

    render json: {data: res_data["ppcs_txnlog_search_response"]}
  end

  def new_trade
    
  end

  def create_trade
  end

  def pay_to_client
    data = params[:pay_to_client]
    res_data = Hash.from_xml pay_for_another data
    render json: {data: res_data}
  end

  private

    def card_params
        params.require(:card).permit(:parent_id)
    end

    def set_card
      @card = Card.find(params[:id])
    end

    def save_log (res_data,card_no,from='')

      @card = Card.find_by_no(card_no)

      @cards_log ||= Logger.new('log/cards.log')

      @cards_log.info("[admin][#{Time.now}]#{res_data}")

      @card_log = CardLog.create(:member_id=>1,
                    :card_no=>card_no,
                    :card_id=>@card.id,
                    :message=>"#{res_data.to_json}")     
    end 

    def get_order_id
        order_id = "999990053990001_#{Time.now.to_i}#{rand(100).to_s}"
    end 

end
