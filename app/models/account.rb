#encoding:utf-8
require 'digest/md5'
require 'pp'
class Account < ActiveRecord::Base

	self.table_name = "sdb_pam_account"	
	attr_accessor :license,:current_password

	belongs_to :manager,:foreign_key=>"account_id"
  	belongs_to :supplier, :foreign_key=>"supplier_id"

	has_one :user, :foreign_key=>"member_id"
	has_one :member,:foreign_key=>"member_id"
	has_one :auth_ext, :foreign_key=>"account_id"

  	has_many :commission,:foreign_key=>"member_id"


	validates :login_name, :presence=>{:presence=>true,:message=>"请填写会员名"}

	validates :login_name, :length=>{:in=>3..50,:message=>"会员名应为3到50个字符"},
						     :if=>Proc.new { |c| c.login_name.present? }

	validates :login_password,  :presence=>{:presence=>true,:message=>"请填写密码"}
	validates :login_password,  :length=>{:minimum=>6,:message=>"密码不能少于6位"},
								:if=>Proc.new{ |c| c.login_password.present? }

	validates :login_password, :confirmation=>{:confirmation=>true,:message=>"两次密码不一致"}
	#validates :login_password_confirmation,:presence=>{:presence=>true,:message=>"请填写确认密码"}
	validates :email,:presence=>{:presence=>true,:message=>"请填写邮箱"}
	validates :email,:format=>{:with=>/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i,:message=>"邮箱格式不正确",:multiline => true},
					    :if=>Proc.new{ |c| c.email.present? }

	validates :mobile,:presence=>{:presence=>true,:message=>"请填写手机"}
	validates :mobile,:format=>{:with=>/^\d{11}$/,:message=>"手机号码必须是11位数字",:multiline => true},
					    :if=>Proc.new{ |c| c.mobile.present? }

    validates :license, :presence=>{:presence=>true,:message=>"您还没有阅读注册协议"}, :if=>Proc.new{ |c| c.new_record? }

	validate :check_login_name_duplicated,:check_email_duplicated,:check_mobile_duplicated #,:check_discount_code_availability


	def check_login_name_duplicated
		return if self.login_name.blank? || self.errors[:login_name].present?
		if Account.find_by_login_name(self.login_name) ||
		   User.find_by_mobile(self.login_name) ||
		   User.find_by_email(self.login_name)
			errors.add(:login_name, "会员名已经被使用！") if new_record?
		end
	end

	# def check_discount_code_availability
	# 	c = DiscountCode.where("code='#{self.discount_code}' and status='true")
	# 	if self.discount_code.present? && c.empty?
	# 		errors.add(:discount_code, "特惠码无效！")
	# 	end
	# end

	def check_mobile_duplicated
	    if self.mobile.present? and u = User.find_by_mobile(self.mobile) and  new_record?
	      errors.add(:mobile, "手机号码已经被使用！")
	    end
	end

	def check_email_duplicated
	    if new_record? and self.email.present? and u = User.find_by_email(self.email)
	      errors.add(:email, "邮箱已经被使用！")
	    end
	end


	validate :check_modify_password


	def check_modify_password
		return true  if  new_record? || self.login_password.present?
		if current_password.blank?
			errors.add(:current_password,"请输入当前密码")
			return false
		end

		right = false
		
		_account =  self.class.find_by_account_id(self.account_id)

		if _account.login_password[0] == "s"
			encrypt = "s" + Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(self.current_password)}#{_account.login_name}#{_account.createtime}")[0..30]
			right  =  (encrypt == _account.login_password)
		else
			right  =  (Digest::MD5.hexdigest(current_password) ==  _account.login_password)
		end

		unless right
			errors.add(:current_password,"输入的当前密码不正确")
		end

		return right
	end

	before_save  :encrypt_password
	

	def self.admin_authenticate(name,password)
		account = self.where(:login_name=>name,:account_type=>"shopadmin").first
		if account
			if account.login_password[0] == "s"
				encrypt = "s" + Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(password)}#{name}#{account.createtime}")[0..30]
				return account if encrypt == account.login_password
			else
				return account if Digest::MD5.hexdigest(password) == account.login_password
			end
		end
		nil
  end

  # def self.vshop_authenticate(name,password)
  #   account = self.where(:login_name=>name,:account_type=>"member").first
  #   if account
  #     if account.login_password[0] == "s"
  #       encrypt = "s" + Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(password)}#{name}#{account.createtime}")[0..30]
  #       return account if encrypt == account.login_password
  #     else
  #       return account if Digest::MD5.hexdigest(password) == account.login_password
  #     end
  #   end
  #   nil
  # end


  def self.user_authenticate_mobile(name,password,supplier_id)
    #username
    #account = self.where(:login_name=>name,:account_type=>"member").first
    #允许后台管理员登录前台
    account = self.where(:login_name=>name,:supplier_id=>supplier_id).first

    unless account
      #email
      if /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i =~ name
        email = name
        user = User.where(:email=>email,:email_validate=>'true',:supplier_id=>supplier_id).first
        account = user.account if user

      end
      #mobile
      if /^[1-9][0-9]{10}$/ =~ name
        mobile = name
        users = User.where(:mobile=>mobile,:sms_validate=>'true',:supplier_id=>supplier_id)
        if users&&users.size == 1
          account = users.first.account if users.first
        end
      end
    end

    if account

      if account.login_password[0] == "s"
        encrypt = "s" + Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(password)}#{account.login_name}#{account.createtime}")[0..30]
        return account if encrypt == account.login_password
      else
        return account if Digest::MD5.hexdigest(password) == account.login_password
      end
    end
    nil
  end

	def self.user_authenticate(name,password)
		#username
		#account = self.where(:login_name=>name,:account_type=>"member").first
    #允许后台管理员登录前台
    account = self.where(:login_name=>name).first

		unless account
			#email
			if /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i =~ name
				email = name
				user = User.where(:email=>email).first
				if user.email_validate=='false'
					errors.add(:name, "邮箱未验证！")
				else
					account = user.account if user
				end
			end
			#mobile
			if /^[1-9][0-9]{10}$/ =~ name
				mobile = name
				users = User.where(:mobile=>mobile,:sms_validate=>'true')
				if users&&users.size == 1
					account = users.first.account if users.first
				end
			end
		end

		if account

			if account.login_password[0] == "s"
				encrypt = "s" + Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(password)}#{account.login_name}#{account.createtime}")[0..30]
				return account if encrypt == account.login_password
			else
				return account if Digest::MD5.hexdigest(password) == account.login_password
			end
		end
		nil
	end


	def self.simple_authenticate(login_name)
		arr_name = login_name.split("_")
		if arr_name.size > 1 && %w(weixin sina douban).include?(arr_name.first)
			account = self.where("login_name like '#{login_name}_%'").first
		else
			account = self.find_by_login_name(login_name)
		end
		account.user if account
	end

	def name
		self.login_name
	end

	def email
		self.user.email if self.user
	end
	
	def email=(val)
		self.user = User.new unless self.user
		self.user.email = val
	end

	def mobile=(val)
		self.user = User.new unless self.user
		self.user.mobile = val
	end

	def mobile
		self.user.mobile if self.user
	end

	# def discount_code=(val)
	# 	self.user = User.new unless self.user
	# 	self.user.discount_code = val
	# end

	# def discount_code
	# 	self.user.discount_code if self.user
	# end

	def real_name=(val)
		self.user = User.new unless self.user
		self.user.name = val
	end

	def real_name
		self.user.name if self.user
	end

	# def auth_ext_id
	# 	self.auth_ext.id if self.auth_ext.id
	# end

	def auth_ext_id=(val)
		self.auth_ext = AuthExt.find(val) if val.present?
	end

	def follow_imodec
		case self.auth_ext.provider
			when 'weibo'
				client = Weibo.new(:access_token=>self.auth_ext.access_token,
									:expires_at=>self.auth_ext.expires_at)
				return true if self.auth_ext.uid.to_s == Weibo.config.uid.to_s
				ship = client.get('friendships/show.json',{:source_id=>client.config.uid,
													:target_id=>self.auth_ext.uid})
				ship.source.followed_by
      when 'douban'
        true
      when 'weixin'
        true
			else
				false
		end
	rescue Exception=>e
		logger.error "check whether '#{self.login_name}' is following 'CQ'. because #{e}"
	end

	def follow_imodec=(val)
		@following = val
	end
	

	def gen_secret_string_for_cookie
		md5_login_name = Digest::MD5.hexdigest(self.login_name)
		md5_password = Digest::MD5.hexdigest(self.login_password)
		"#{self.account_id}-#{md5_login_name}-#{md5_password}-#{Time.now.to_i}"
	end

	def super?
		return false if self.account_type!="shopadmin"
		self.manager.super == "1"
	end

	def has_right_of(controller=nil,action=nil)

		raise "you are not manager" if self.account_type!="shopadmin"
		
		return self.manager.has_right_of(controller,action)

		return true if self.manager.super=="1"
		return false unless self.manager.permission
		rights = ActiveSupport::JSON.decode(self.manager.permission.rights)

		if action.blank?
			return rights[controller.to_s]&&rights[controller.to_s].select{|k,v| v == "1"}.size > 0
		else
			return rights[controller.to_s]&&rights[controller.to_s][action.to_s] == "1"
		end
	end

	
	private

	def encrypt_password
		self.login_password =  "s" + Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(self.login_password)}#{self.login_name}#{self.createtime}")[0..30]
	end

end