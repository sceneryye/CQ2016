# encoding: utf-8
# 1, @weixin_message: 获取微信所有参数.
# 2, @weixin_public_account: 如果配置了public_account_class选项,则会返回当前实例,否则返回nil.
# 3, @keyword: 目前微信只有这三种情况存在关键字: 文本消息, 事件推送, 接收语音识别结果
WeixinRailsMiddleware::WeixinController.class_eval do

  def reply
    case @keyword
      when '地址'
        render xml: send("response_location_message", {})  
      when 'TESTCOMPONENT_MSG_TYPE_TEXT' 
        render xml: send("response_text_message", {})
      else
        render xml: send("response_news_message", {})    
       #render xml: send("response_#{@weixin_message.MsgType}_message", {})
    end

  end

  private

  def response_news_message(options={})
    id = 1 #@weixin_public_account.id
    user = @weixin_message.FromUserName
    #user = @weixin_message.ToUserName
    
    title="CQ基地风光有您的地吗？"
    desc ="CQ基地是一家以出租生态土地，为会员免费定制种植各种生态产品的服务平台。"
    pic_url="http://www.cq2016.cc/images/show/welcome2.jpg"
    link_url="http://www.cq2016.cc/?from=weixin_menu"

    case @keyword     
      when 'subscribe'
        title="您好！昌麒生态园欢迎家人的到来！"
        desc ="鲶鱼沟人，用智慧和生命力，在这片土地上完成了伟大的孕育。在碱性环境里培植优质营养的碱地大米、五谷杂粮、养殖有机大雁和绿色河蟹，使之成为名副其实的北国鱼米之乡。"
        pic_url="http://www.cq2016.cc/images/show/welcome2.jpg"
        link_url="http://www.cq2016.cc/?from=weixin_menu"     
      else
        desc =""
        title="您好！昌麒生态园欢迎家人的到来！"
        pic_url="http://www.cq2016.cc/images/show/welcome.jpg"
        link_url="http://www.cq2016.cc/?from=weixin_menu"
    end

    articles = [generate_article(title, desc, pic_url, link_url)]
    if articles
      reply_news_message(articles)
    end
  end

  def response_text_message(options={})
    case @keyword
    when 'TESTCOMPONENT_MSG_TYPE_TEXT'
        message = 'TESTCOMPONENT_MSG_TYPE_TEXT_callback'
    else
      message="您好！#{@weixin_public_account.name},欢迎您！"
    end

    #reply_text_message("Your Message: #{@keyword}")

   # message="您好！#{@weixin_public_account.name}欢迎您！"

    # message="您好！昌麒生态园欢迎家人的到来！"
    reply_text_message(message)
  end

  # <Location_X>23.134521</Location_X>
  # <Location_Y>113.358803</Location_Y>
  # <Scale>20</Scale>
  # <Label><![CDATA[位置信息]]></Label>
  def response_location_message(options={})
    @lx    = @weixin_message.Location_X
    @ly    = @weixin_message.Location_Y
    @scale = @weixin_message.Scale
    @label = @weixin_message.Label
    #   reply_text_message("您现在的位置是: #{@lx}, #{@ly}, #{@scale}, #{@label}")
  end

  # <PicUrl><![CDATA[this is a url]]></PicUrl>
  # <MediaId><![CDATA[media_id]]></MediaId>
  def response_image_message(options={})
    @media_id = @weixin_message.MediaId # 可以调用多媒体文件下载接口拉取数据。
    @pic_url  = @weixin_message.PicUrl  # 也可以直接通过此链接下载图片, 建议使用carrierwave.
    reply_image_message(generate_image(@media_id))
  end

  # <Title><![CDATA[公众平台官网链接]]></Title>
  # <Description><![CDATA[公众平台官网链接]]></Description>
  # <Url><![CDATA[url]]></Url>
  def response_link_message(options={})
    @title = @weixin_message.Title
    @desc  = @weixin_message.Description
    @url   = @weixin_message.Url
#    reply_text_message("回复链接信息")

  end

  # <MediaId><![CDATA[media_id]]></MediaId>
  # <Format><![CDATA[Format]]></Format>
  def response_voice_message(options={})
    @media_id = @weixin_message.MediaId # 可以调用多媒体文件下载接口拉取数据。
    @format   = @weixin_message.Format
    # 如果开启了语音翻译功能，@keyword则为翻译的结果
    # reply_text_message("回复语音信息: #{@keyword}")
    reply_voice_message(generate_voice(@media_id))
  end

  # <MediaId><![CDATA[media_id]]></MediaId>
  # <ThumbMediaId><![CDATA[thumb_media_id]]></ThumbMediaId>
  def response_video_message(options={})
    @media_id = @weixin_message.MediaId # 可以调用多媒体文件下载接口拉取数据。
    # 视频消息缩略图的媒体id，可以调用多媒体文件下载接口拉取数据。
    @thumb_media_id = @weixin_message.ThumbMediaId
    #  reply_text_message("回复视频信息")
  end

  def response_event_message(options={})
    event_type = @weixin_message.Event
    send("handle_#{event_type.downcase}_event")
  end


  private

  # 关注公众账号
  def handle_subscribe_event
    if @keyword.present?
      # 扫描带参数二维码事件: 1. 会员未关注时，进行关注后的事件推送
      #  return reply_text_message("扫描带参数二维码事件: 1. 会员未关注时，进行关注后的事件推送, keyword: #{@keyword}")
    end
   # reply_text_message("感谢您关注保亨生物--昌麒投资茶")
    @keyword = "subscribe"
    response_news_message()
  end

  # 取消关注
  def handle_unsubscribe_event
    Rails.logger.info("#{@weixin_message.FromUserName} 取消关注")
  end

  # 扫描带参数二维码事件: 2. 会员已关注时的事件推送
  def handle_scan_event
    # reply_text_message("扫描带参数二维码事件: 2. 会员已关注时的事件推送, keyword: #{@keyword}")
  end

  def handle_location_event # 上报地理位置事件
    @lat = @weixin_message.Latitude
    @lgt = @weixin_message.Longitude
    @precision = @weixin_message.Precision
    # reply_text_message("Your Location: #{@lat}, #{@lgt}, #{@precision}")
  end

  # 点击菜单拉取消息时的事件推送
  def handle_click_event

    case @keyword
      when 'ON_SALE'
        @keyword='on_sale'
        response_news_message({})
      when 'NEW'
        @keyword='new'
        response_news_message({})
      when 'SHARE'
        @keyword='share'
        response_news_message({})
      when 'Oauth'
        @keyword='授权'
        response_news_message({})
      else
        # reply_text_message("你点击了: #{@keyword}")
    end
  end

  # 点击菜单跳转链接时的事件推送
  def handle_view_event
    Rails.logger.info("你点击了: #{@keyword}")
    #  reply_text_message("你点击了: #{@keyword}")
    session[:wechat_user]= @weixin_message.FromUserName
  end

  # 帮助文档: https://github.com/lanrion/weixin_authorize/issues/22

  # 由于群发任务提交后，群发任务可能在一定时间后才完成，因此，群发接口调用时，仅会给出群发任务是否提交成功的提示，若群发任务提交成功，则在群发任务结束时，会向开发者在公众平台填写的开发者URL（callback URL）推送事件。

  # 推送的XML结构如下（发送成功时）：

  # <xml>
  # <ToUserName><![CDATA[gh_3e8adccde292]]></ToUserName>
  # <FromUserName><![CDATA[oR5Gjjl_eiZoUpGozMo7dbBJ362A]]></FromUserName>
  # <CreateTime>1394524295</CreateTime>
  # <MsgType><![CDATA[event]]></MsgType>
  # <Event><![CDATA[MASSSENDJOBFINISH]]></Event>
  # <MsgID>1988</MsgID>
  # <Status><![CDATA[sendsuccess]]></Status>
  # <TotalCount>100</TotalCount>
  # <FilterCount>80</FilterCount>
  # <SentCount>75</SentCount>
  # <ErrorCount>5</ErrorCount>
  # </xml>
  def handle_masssendjobfinish_event
    Rails.logger.info("回调事件处理")
  end

end
