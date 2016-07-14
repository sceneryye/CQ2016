#encoding:utf-8
class CardTrading < ActiveRecord::Base
  	
  	belongs_to :card
  	has_many :rebates, dependent: :destroy

  	def type_text
  		return '线上交易' if self.trading_type==0
  		return '线下交易' if self.trading_type==1
  	end
end