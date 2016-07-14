#encoding:utf-8
class UserMailer < ActionMailer::Base
  async = true
  
  default from: "昌麒投资茶<cs@iotps.com>"


  def user_email(addr,subject)
  	mail(:to => addr, :subject => subject)
  end

end
