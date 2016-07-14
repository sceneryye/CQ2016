class Rebate < ActiveRecord::Base

	 belongs_to :user, :foreign_key=>"member_id"
	 belongs_to :card_trading
	 belongs_to :withdrawal

	 def type_text
	 	return '消费提现' if self.rebate_type=='0'
	 	return '子卡提现' if self.rebate_type =='1'
	 end

end