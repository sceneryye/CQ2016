#encoding:utf-8
class Delivery < ActiveRecord::Base
	self.table_name = 'sdb_b2c_delivery'

	has_many :delivery_items, :foreign_key=>"delivery_id", :class_name=>"DeliveryItem"

	accepts_nested_attributes_for :delivery_items, allow_destroy: true
	#attr_accessor
	belongs_to :dlycorp, :foreign_key=>"logi_id"

	validates_presence_of :logi_id,:message=>"必须填写物流公司"
	validates_presence_of :ship_name,:message=>"必须填写收货人"

	validates_presence_of :ship_addr,:message=>"必须填写收货地址"

	validates :ship_mobile, presence: { presence: true, message: "必须填写手机号码" },
	                                      format: { with: /^\d{11}$/, message: "手机号码必须是11位数字",multiline:true }

	validate :check_area

	belongs_to :order,:foreign_key=>"order_id"

	attr_accessor :province,:city,:district

	include AddressFields

	before_save :make_area
	after_save :update_order_items
	before_create :set_delivery_id

	def delivery_items=(dly_items)
		dly_items.each do |item|
			_item = DeliveryItem.new(item)
			self.delivery_items << _item if _item.number > 0
		end
	end

	def update_order_items

		self.delivery_items.each do |dly_item|
			# update order_item send_num
			order_item = OrderItem.find_by_item_id(dly_item.order_item_id)
			order_item.update_attribute :sendnum, order_item.sendnum.to_i + dly_item.number if order_item

			# update product store
			product = order_item.product
			if product
				product.update_attribute :freez, (product.freez.to_i + dly_item.number)
				product.update_attribute :store, (product.store.to_i - dly_item.number)
			end
		end

		#  update order ship_status
		dly_ids = Delivery.where(:order_id=>self.order_id).pluck(:delivery_id)
		send_total = DeliveryItem.where(:delivery_id=>dly_ids).sum("number")

		order_total = OrderItem.where(:order_id=>self.order_id).sum("nums")

		op = Account.find_by_login_name(self.op_name)
		order_log = OrderLog.new do |order_log|
			order_log.rel_id = self.order_id
			order_log.op_id = op.account_id
			order_log.op_name = self.op_name
			order_log.alttime = self.t_begin
			order_log.behavior = 'delivery'
			order_log.result = "SUCCESS"
		end

		# 部分发货
		if send_total > 0 && send_total < order_total
			self.order.update_attribute :ship_status, '2'
			order_log.log_text = {:txt_key=>"部分商品发货 ! ",:delivery_id=>self.delivery_id}.serialize
			order_log.save
		end

		# 已发货
		if send_total > 0 && send_total == order_total
			self.order.update_attribute :ship_status, '1'
			order_log.log_text = {:txt_key=>"商品已发货 ! ",:delivery_id=>self.delivery_id}.serialize
			order_log.save
		end
	end


	def set_delivery_id
		self.delivery_id = self.class.generate_delivery_id
	end

	def self.generate_delivery_id
	    _time = "1#{Time.now.strftime('%Y%m%d%H%M%S')}"
	    seq = rand(10000)
          loop do
          	  _dly_id = "#{_time}#{seq}"
              return _dly_id  unless Delivery.find_by_delivery_id(_dly_id)
              seq = 1 if seq == 9999
              seq += 1
          end
	end

    def check_area
  		if province.blank? || city.blank?
  		    self.errors.add(:ship_area, "请选择送货地区")
  		else
  			if Region.find_by_region_id(city).subregions.size > 0
  				self.errors.add(:ship_area, "请选择送货地区") if district.blank?
  			end
  		end
    end

end
