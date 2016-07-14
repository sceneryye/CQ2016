#encoding:utf-8

#require 'allinpay'
require 'digest/md5'
require 'openssl'
require 'base64'
require 'rest-client'
require 'net/http'
require 'net/https'
  

class Admin::WithdrawalsController < Admin::BaseController
	before_filter :require_permission!

	PAY_CUR = 'CNY'
  PUBLIC_FILE = 'allinpay-pds.cer'
  SIGN_V = '1'

	 URL = 'http://116.228.223.212:7001/aop/rest'
      MER_ID = '999331054990016'
      APPSECRET = '800001671aopreq20160505174758rygZwewN'
      APP_KEY = '80000167' 
      PRDT_NO = "0002"    
      KEY = '6223e3c4'
      IV = '6223e3c4'    
      #验签版本号:1
      #请求密钥:800001671aopreq20160505174758rygZwewN
      #响应密钥:800001671aopres201605051747582BW2M3L6
      
      MERCHANT_ID = '200331000015666'
      PAY_URL = 'https://tlt.allinpay.com:443/aipg/ProcessServlet'
      USER_NAME = '20033100001566604'
      USER_PASS = '111111'
      PRIVATE_FILE ='20033100001566604.p12'
     


	def show

	end
	  
	def index

		xml = get_account_info
		# return render text: xml

		hash = Hash.from_xml(xml)
		if hash["AIPG"]["INFO"]["RET_CODE"] =='0000'
			@balance =  hash["AIPG"]["ACQUERYREP"]["ACNODE"][0]["BALANCE"].to_f/100
		else
			@balance = ["AIPG"]["INFO"]["ERR_MSG"]
		end

	   @status = params[:status].to_i
		if @status.blank?
			@status = 0		
		end

		case @status 
		when 0
			@s0 = 'disabled'
		when 1
			@s1 = 'disabled'
		when 2
			@s2 = 'disabled'
		when -1
			@s_1 = 'disabled'
		when -2
			@s_2 = 'disabled'
		end	

		@withdrawals =   Withdrawal.where(status: @status)	

	    @withdrawals_total = @withdrawals.count
	    @withdrawals = @withdrawals.paginate(:page=>params[:page],:per_page=>20)	   

		

	end

	def pay
		
		id = params[:id]
		@withdrawal = Withdrawal.where(id: id,status: 0)
		if @withdrawal.present?
			@withdrawal = @withdrawal.first
		else
			return render text:'提现申请不存在或者已经发放提现'
		end

    	data = {SN: '0001',
    			E_USER_CODE: @withdrawal.id,
    			#BANK_CODE: '0105',
    			ACCOUNT_NO:  @withdrawal.user.member_card.bank_card_no,
				ACCOUNT_NAME: @withdrawal.user.member_card.user_name,
				ACCOUNT_PROP: 0,
				AMOUNT: (@withdrawal.amount*100).to_i
				#CURRENCY: 'CNY',
    			#TEL: '13434245846',
    			#CUST_USERID: '252523524253xx'
			}

		xml = pay_for_another id,data

		hash = Hash.from_xml(xml)
		if hash["AIPG"]["INFO"]["RET_CODE"] =='0000'
			@withdrawal.update_attribute :status,1
			return redirect_to admin_withdrawals_path(status: 1)
		else
			return render text: hash
		end
		
		 # return render text: xml
	    # res_data = Hash.from_xml pay_for_another data
	    # return render text: res_data
	    # render json: {data: res_data}
	end

	def update
	end

	private

	def timestamps
      Time.now.strftime('%Y%m%d%H%M%S')
    end

    def get_account_info
	    mer_tm = timestamps
	    req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')
	    business_code = '09900' #'09400' 

	    info_hash = {TRX_CODE: '300000', VERSION: '03', DATA_TYPE: '2', LEVEL: '9', 
	    			MERCHANT_ID: MERCHANT_ID, USER_NAME: USER_NAME, USER_PASS: USER_PASS,
	    			REQ_SN: req_sn,REQTIME: mer_tm}
	    data_hash = {ACQUERYREQ: {ACCTNO:''}}
	   
	   	data_hash = {INFO:info_hash}.merge data_hash


      	data_xml = data_hash.to_xml(root: "AIPG",skip_types: true, dasherize: false).sub('UTF-8', 'GBK')

		data_xml.encode! 'gbk','utf-8'
  		# return render text: data_xml

	    p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("/root/web/cq2016/lib/#{PRIVATE_FILE}", __FILE__)), USER_PASS)
	    
	    key = p12.key

	    pri = OpenSSL::PKey::RSA.new key.export

	    sign = pri.sign("sha1", data_xml.force_encoding("GBK"))
	    # pub_key = pri.public_key
	    # result = pub_key.verify('sha1', sign, data_xml.force_encoding("GBK"))
	    #return render text: "verify #{result ? 'successful!' : 'failed!'}"
		
	    data_xml = data_xml.sub('</REQ_SN>',"</REQ_SN><SIGNED_MSG>#{sign.unpack('H*').first}</SIGNED_MSG>")

	    # return render text: data_xml
	     

		uri = URI(PAY_URL)
	    response = Net::HTTP.start(uri.host, uri.port,:use_ssl => uri.scheme == 'https') do |http|
	    	http.use_ssl = true
		    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		 	#http.ca_path = '/root/web/cq2016/lib/'
			#http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	     	req = Net::HTTP::Post.new uri.path, initheader = {'Content-Type' =>'text/xml'}	 
	     	req.basic_auth USER_NAME, USER_PASS  
		    req.body = data_xml		
		
			http.request req
		end

	    res_data_xml = response.body.encode('utf-8','gbk').sub('GBK', 'UTF-8')
	     

	   res_data_xml
	end

	def pay_for_another withdrawal_id,options
	    mer_tm = timestamps
	    req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')
	    business_code = '09900' #'09400' 

	    info_hash = {TRX_CODE: '100002', VERSION: '03', DATA_TYPE: '2', LEVEL: '9', 
	    			 USER_NAME: USER_NAME, USER_PASS: USER_PASS,REQ_SN: req_sn}
	    trans_sum = {BUSINESS_CODE: business_code, MERCHANT_ID: MERCHANT_ID,SUBMIT_TIME: mer_tm,
	    			 TOTAL_ITEM: 1, TOTAL_SUM: options[:AMOUNT]}
	    trans_details =  {TRANS_DETAILS: {TRANS_DETAIL: options}}
	   	data_hash = {TRANS_SUM:trans_sum}.merge trans_details
	   	data_hash = {BODY:data_hash}
	   	data_hash = {INFO:info_hash}.merge data_hash


	 	#    options = {BUSINESS_CODE: business_code, MERCHANT_ID: MERCHANT_ID,SUBMIT_TIME: mer_tm}.merge! options
		# options = {TRANS:options}
		# info_hash = {TRX_CODE: '100002', VERSION: '03', DATA_TYPE: '2', LEVEL: '9', MERCHANT_ID: MERCHANT_ID,
  		#                   USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn}
  		#       data_hash = {INFO:info_hash}.merge options

      	data_xml = data_hash.to_xml(root: "AIPG",skip_types: true, dasherize: false).sub('UTF-8', 'GBK')

		data_xml.encode! 'gbk','utf-8'
  		# return render text: data_xml

	    p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("/root/web/cq2016/lib/#{PRIVATE_FILE}", __FILE__)), USER_PASS)
	    
	    key = p12.key

	    pri = OpenSSL::PKey::RSA.new key.export

	    sign = pri.sign("sha1", data_xml.force_encoding("GBK"))
	    # pub_key = pri.public_key
	    # result = pub_key.verify('sha1', sign, data_xml.force_encoding("GBK"))
	    #return render text: "verify #{result ? 'successful!' : 'failed!'}"
		
	    data_xml = data_xml.sub('</REQ_SN>',"</REQ_SN><SIGNED_MSG>#{sign.unpack('H*').first}</SIGNED_MSG>")

	    # return render text: data_xml
	     

		uri = URI(PAY_URL)
	    response = Net::HTTP.start(uri.host, uri.port,:use_ssl => uri.scheme == 'https') do |http|
	    	http.use_ssl = true
		    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		 	#http.ca_path = '/root/web/cq2016/lib/'
			#http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	     	req = Net::HTTP::Post.new uri.path, initheader = {'Content-Type' =>'text/xml'}	 
	     	req.basic_auth USER_NAME, USER_PASS  
		    req.body = data_xml		
		
			http.request req
		end

	    res_data_xml = response.body.encode('utf-8','gbk')
	     
	    @log = WithdrawalLog.create(:withdrawal_id => withdrawal_id,
						  			:request => data_xml.encode('utf-8','gbk'),
						  			:response => res_data_xml)

	    res_data_xml
	end

	def create_sign_for_another xml
	    p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("/root/web/cq2016/lib/#{PRIVATE_FILE}", __FILE__)), USER_PASS)

	    key = p12.key
	    pri = OpenSSL::PKey::RSA.new key.to_s
	    sign = pri.sign("sha1", xml)
	end

end
