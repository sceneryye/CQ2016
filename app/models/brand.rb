#encoding:utf-8
class Brand < ActiveRecord::Base

	include Metable

	extend FriendlyId
	friendly_id :brand_name, :use => [:slugged, :finders]

	self.primary_key = 'brand_id'
	has_many :goods,->{where(marketable:'true')}, :foreign_key=>"brand_id"

	has_one :seo,->{where(mr_id:3) }, :foreign_key=>:pk

	has_many :addresses, :as=>:addressable

	accepts_nested_attributes_for :addresses, :allow_destroy=>true

	has_one :offline_coupon


	default_scope {where(disabled: 'false')}

	
	scope :menu_brands,->{order("ordernum desc")}


	validates_presence_of :brand_name,:message=>"基地名称不能为空"
	validates_presence_of :slug,:message=>"访问地址不能为空"
	validates_uniqueness_of :slug,:message=>"您输入的访问地址已经存在"

	def context=(val)
	  	super(val.to_json)
	end

	  def context
	  	return ActiveSupport::JSON.decode super if super.present?
	  	return []
	  end


	def logo_url
		if File.exists?("#{Rails.root}/public/pic/logos/#{self.brand_name.strip}.png")
			"/pic/logos/#{self.brand_name.strip}.png"
		else
			nil
		end
	end

	def list_logo
		if File.exists?("#{Rails.root}/public/pic/brands/#{self.slug}.gif")
			"/pic/logos/#{self.slug}.gif"
		else
			nil
		end
	end
end