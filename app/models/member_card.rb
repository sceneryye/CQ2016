#encoding:utf-8
class MemberCard < ActiveRecord::Base
	self.table_name = "member_cards"

	belongs_to :card, :foreign_key=>"card_id"
	belongs_to :buyer, :foreign_key=>"buyer_id",:class_name=>"User"
	belongs_to :user, :foreign_key=>"user_id",:class_name=>"User"
	belongs_to :user, :foreign_key=>"member_id"

	# validates :user_tel,
	# 		   :presence=>{:presence=>true,:message=>"请填写手机号码"},
	# 		   :if=>Proc.new{ |c| c.card.card_type == 'A' }

	# validates :user_tel,
	# 		   :format=>{:with=>/^\d{11}$/, :multiline => true,:message=>"使用者手机号码必须是11位数字"},
	# 		   :if=>Proc.new{ |c| c.card.card_type == 'A' }

	# validates :buyer_tel,:presence=>{:presence=>true,:message=>"请填写手机号码"}
	# validates :buyer_tel,:format=>{:with=>/^\d{11}$/, :multiline => true,:message=>"购买者手机号码必须是11位数字"}

	# validates :bank_card_no,
	# 		  :format=>{:with=>/^(\d{16}|\d{19})$/, :multiline => true,:message=>"银行卡号必须是16位或者19位数字"}
	 
	
	after_save :sell_card!

	def sell_card!
		self.card.update_attribute :sale_status, true if self.card
	end

	def subcards
		Card.where(parent_id: self.card_id)
	end

	def tradings_log (status=1)

		# all_cards = Card.where("id=#{self.card} and parent_id =#{self.card_id}")
		all_cards_ids = Card.select{|card| card.id==self.card_id || card.parent_id == self.card_id}.collect{ |card|card.id }.join(',')

		CardTrading.where("status=#{status} and card_id in (#{all_cards_ids})")
	end
end