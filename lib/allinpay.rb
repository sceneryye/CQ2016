require 'digest/md5'
require 'openssl'
require 'base64'
require 'rest-client'

module Allinpay
  PAY_CUR = 'CNY'
  PUBLIC_FILE = 'allinpay-pds.cer'
  SIGN_V = '1'

  # # test
  #   URL = 'http://116.236.192.117:8080/aop/rest'
  #   MER_ID = '999990053990001'
  #   APPSECRET = 'test'
  #   APP_KEY = 'test'
  #   KEY = 'abcdefgh'
  #   IV = 'abcdefgh'
  #   PRDT_NO = "0001"

  #   PAY_URL = 'https://113.108.182.3:443/aipg/ProcessServlet'
  #   USER_NAME = '20060400000044502'
  #   USER_PASS = '111111'
  #   PRIVATE_FILE ='20060400000044502.p12'    
  #   MERCHANT_ID = '999990053990001' #'200604000000445'
  # #----

  # product
      URL = 'http://116.228.223.212:7001/aop/rest'
      MER_ID = '999331054990016'
      APPSECRET = '800001671aopreq20160505174758rygZwewN'
      APP_KEY = '80000167' 
      PRDT_NO = "0002"    
      KEY = '6223e3c4'
      IV = '6223e3c4'    
      
      MERCHANT_ID = '200604000000445'
      PAY_URL = 'https://tlt.allinpay.com:443/aipg/ProcessServlet'
      USER_NAME = '20033100001566604'
      USER_PASS = '111111'
      PRIVATE_FILE ='20033100001566604.p12'
      #验签版本号:1
      #请求密钥:800001671aopreq20160505174758rygZwewN
      #响应密钥:800001671aopres201605051747582BW2M3L6
  #----   

  def pay_for_another options
    mer_tm = timestamps
    req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')
    data_hash = {TRX_CODE: '100014', VERSION: '03', DATA_TYPE: 2, LEVEL: 9, USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn, BUSINESS_CODE: '10800', MERCHANT_ID: MERCHANT_ID, SUBMIT_TIME: mer_tm}.merge! options
    data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
    sign = create_sign_for_another data_xml
    data_hash.merge! sign: sign
    data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
    Rails.logger.info data_xml
    res_data_xml = RestClient.post PAY_URL, data_xml, content_type: :xml
    # res_data_xml = RestClient::Request.execute(method: post, ) PAY_URL, data_xml, content_type: :xml
  end

  def create_sign_for_another xml
    p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("../#{CER_FILE}", __FILE__)), USER_PASS)
    key = p12.key
    pri = OpenSSL::PKey::RSA.new key.to_s
    sign = pri.sign("sha1", xml)
  end

  def idcard_verify name, id_no
    ###############_not_finished
      timestamps = Time.now.strftime('%Y%m%d%H%M%S')
      mer_tm = timestamps
      req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')

      options = {IDVER:{NAME: '刘龙英', IDNO: '332522195812245684',VALIDATA: '', REMARK: '单笔实时身份验证'}}


      data_hash = {INFO:{TRX_CODE: '220001', VERSION: '03', DATA_TYPE: 2, LEVEL: 5, MERCHANT_ID: MERCHANT_ID,
                    USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn, BUSINESS_CODE: '10800',
                    MERCHANT_ID: MERCHANT_ID, SUBMIT_TIME: mer_tm}}.merge! options

      data_xml = data_hash.to_xml.sub('UTF-8', 'GBK').gsub('hash','AIPG').gsub('-','_')
     
      p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("../../../../lib/#{PRIVATE_FILE}", __FILE__)), USER_PASS)
      # return render text: p12.certificate.to_pem 

      # 证书 # puts p12.certificate.to_pem 
      # 私钥  # puts p12.key.export
      key = p12.key

      pri = OpenSSL::PKey::RSA.new key.export
      #Base64.encode64(OpenSSL::PKey::RSA.new(PRIVATEKEY).sign('sha1', data.force_encoding("utf-8"))).gsub("\n", "")
      sign = pri.sign("sha1", data_xml.force_encoding("GBK"))

      # return render text: "#{sign.unpack('H*').first}"
      # pub = OpenSSL::X509::Certificate.new (File.read(File.expand_path("../../../../lib/#{PUBLIC_FILE}", __FILE__)))
      pub_key = pri.public_key
      result = pub_key.verify('sha1', sign, data_xml.force_encoding("GBK"))
      # return render text: "verify #{result ? 'successful!' : 'failed!'}"

      data_xml = data_xml.sub('</SUBMIT_TIME>',"</SUBMIT_TIME><SIGNED_MSG>#{sign.unpack('H*').first}</SIGNED_MSG>")
      # return render text: data_xml
      # request = Typhoeus::Request.new(PAY_URL, method: :post, params: data_xml, ssl_verifypeer: false, headers: {'Content-Type' =>'application/x-www-form-urlencoded'} )
      # request.run
      # return render text: request.response.to_json
      # if request.response.success?
      #   res_data_xml = Hash[*request.response.body.split("&").map{|a| a.gsub("==", "@@").split("=")}.flatten]['tn']
      # else
      #   res_data_xml = ""
      # end
      uri = URI.parse(PAY_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new("/aipg/ProcessServlet")
      request.add_field('Content-Type', 'text/xml')
      #request.body = post_data.to_json
      response = http.request(request)
      res_data_xml = response.body

     #res_data_xml = RestClient.post PAY_URL, data_xml, content_type: "text/xml"

      return render text: res_data_xml
  end

  def bank_card_verify bank_name, bank_branch, bank_no
  end


  def card_get_info card_id, password
    mer_tm = timestamps
    encrypt_password = des_encrypt password, mer_tm
    data_hash = (public_params 'allinpay.card.cardinfo.get', mer_tm).merge(card_id: card_id, password: encrypt_password)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end


  def card_active card_id, type, desc = 'active card'
    data_hash = (public_params 'allinpay.ppcs.cardsingleactive.add', timestamps).merge(
                  order_id: get_order_id, card_id: card_id, type: type, desc: desc)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def topup_single_card card_id, amount, opr_id, desn = 'topup card'
    top_up_way = '1'
    data_hash = (public_params 'allinpay.ppcs.cardsingletopup.add', timestamps).merge({order_id: get_order_id, card_id: card_id,
      prdt_no: PRDT_NO, amount: amount, top_up_way: top_up_way, opr_id: opr_id, desn: desn})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def pay_with_password amount, card_id, password,mer_order_id='' , options = {}
    type = '01'
    order_id = get_order_id
    if mer_order_id.blank?
      mer_order_id = order_id
    end
    mer_tm = timestamps
    payment_id = "000000#{PRDT_NO}"
    encrypt_card_id = des_encrypt card_id, mer_tm
    encrypt_password = des_encrypt password, mer_tm
    data_hash = (public_params 'allinpay.card.paywithpassword.add', mer_tm).merge(
          pay_cur: PAY_CUR, type: type, mer_id: MER_ID, mer_tm: mer_tm, order_id: order_id, 
          mer_order_id: mer_order_id, payment_id: payment_id, amount: amount).merge options
    
    data_hash.merge!({card_id: encrypt_card_id, password: encrypt_password})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_reset_password card_id, password, options = {}
    mer_tm = timestamps
    data_hash = (public_params 'allinpay.ppcs.cardpassword.rest', mer_tm).merge(order_id: get_order_id, card_id: card_id).merge options
    encrypt_password = des_encrypt password, mer_tm
    data_hash.merge!({password: encrypt_password})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_freeze card_id, reason
    data_hash = (public_params 'allinpay.ppcs.cardproductfreeze.add', timestamps).merge(
                order_id: get_order_id, card_id: card_id, prdt_id: PRDT_NO, reason: reason)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})    
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_unfreeze card_id, reason
    data_hash = (public_params 'allinpay.ppcs.cardproductunfreeze.add', timestamps).merge(
                          order_id: get_order_id, card_id: card_id, prdt_id:PRDT_NO, reason: reason)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_report_loss card_id, id_type, id_no, reason
    data_hash = (public_params 'allinpay.ppcs.cardreportloss.add', timestamps).merge(
                  order_id: get_order_id, card_id: card_id, id_type: id_type, id_no: id_no, reason: reason)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_cancel_loss card_id, id_type, id_no, reason
    data_hash = (public_params 'allinpay.ppcs.cardcancelloss.add', timestamps).merge(
          order_id: get_order_id, card_id: card_id, id_type: id_type, id_no: id_no, reason: reason)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_get_trade_log begin_date, end_date, card_id, password, page_no, page_size
    mer_tm = timestamps
    data_hash = (public_params 'allinpay.card.txnlogByCardId.search', mer_tm).merge(
            begin_date: begin_date, end_date: end_date, card_id: card_id, page_no: page_no, page_size: page_size)
    encrypt_password = des_encrypt password, mer_tm
    data_hash.merge!(password: encrypt_password)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.post URL, send_data
  end

  
  private
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
            #{"card_cardinfo_get_response":{"res_timestamp":20160406213434,"res_sign":"77AFA3C325F8E63404A573B3C306E468","card_info":{"card_stat":0,"brh_id":"0229000040","brand_id":"0001","validity_date":20170210,"card_id":8668083660000001017,"card_product_info_arrays":{"card_product_info":[{"product_stat":0,"product_id":"0001","product_name":"通用金额","validity_date":20170210,"valid_balance":476631,"card_id":8668083660000001017,"account_balance":486631},{"product_stat":0,"product_id":"0282","product_name":"200元现金券","validity_date":20991231,"valid_balance":553619,"card_id":8668083660000001017,"account_balance":553619},{"product_stat":0,"product_id":1000,"product_name":"积分","validity_date":20160210,"valid_balance":1745700,"card_id":8668083660000001017,"account_balance":1745700}]}}}}
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

    def get_order_id
      order_id = "999990053990001_#{Time.now.to_i}#{rand(100).to_s}"
    end  

    def timestamps
      Time.now.strftime('%Y%m%d%H%M%S')
    end

    def public_params method, timestamp
      data = {app_key: APP_KEY, method: method, timestamp: timestamp, v: '1.0', sign_v: SIGN_V, format: 'json'}
    end

    def create_sign_for_allin hash
      str = hash.select{|key, val| val.present?}.sort_by{ |key,val| key }.collect{|key,val| "#{key}#{val}" }.join('')
      
      unencrypt_str = APPSECRET + str + APPSECRET
      Rails.logger.info "----------------unencrypt_str = #{unencrypt_str}"
      sign = (Digest::MD5.hexdigest unencrypt_str).upcase
    end

    def des_encrypt message, timestamp
      str = timestamp + 'aop' + message
      # str = "20160325161914aop8668083660000001017"
      des = OpenSSL::Cipher.new('DES-CBC')
      des.encrypt
      des.key = KEY
      des.iv = IV
      cipher = des.update(str)
      cipher << des.final
      Rails.logger.info "------------------en_pwd = #{Base64.encode64(cipher)}"
      Base64.encode64(cipher)
    end

end












