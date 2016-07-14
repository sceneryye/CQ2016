require 'active_api'
if Rails.env == 'development'
  ActiveApi.register :weixin do
    config.site = "https://open.weixin.qq.com/"
    config.api_site = "https://open.weixin.qq.com/"
    config.client_id = "wxf9945fddc9b67aaa"
    config.client_secret =  "b2248ee62274de8680d26e6e355c350a"
    config.redirect_uri = "http://www.cq2016.cc/auth/weixin/callback"
    config.ssl = { :ca_path=>"/usr/lib/ssl/certs" }
    config.authorize_uri = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    config.access_token_uri = 'https://api.weixin.qq.com/sns/oauth2/access_token'
    config.path_prefix = '2/'
    config.uid = 'gh_64cd6ce595eb'
    #https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=SCOPE&state=STATE#wechat_redirect
  end
	
end
if Rails.env == 'production'
  ActiveApi.register :weixin do
    config.site = "https://open.weixin.qq.com/"
    config.api_site = "https://open.weixin.qq.com/"
    config.client_id = "wxf9945fddc9b67aaa"
    config.client_secret =  "b2248ee62274de8680d26e6e355c350a"
    config.redirect_uri = "http://www.cq2016.cc/auth/weixin/callback"
    config.ssl = { :ca_path=>"/usr/lib/ssl/certs" }
    config.authorize_uri = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    config.access_token_uri = 'https://open.weixin.qq.com/connect/oauth2/access_token'
    config.path_prefix = '2/'
    config.uid = 'gh_64cd6ce595eb'
    #https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=SCOPE&state=STATE#wechat_redirect
  end	
end

