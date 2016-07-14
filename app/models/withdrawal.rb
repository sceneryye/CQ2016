class Withdrawal < ActiveRecord::Base

	belongs_to :user, :foreign_key=>"member_id"
	has_many :rebates
	has_many :withdrawal_logs

	def status_text
	 	return '申请提现' if status == 0
	 	return '提现中' if status == 1
	 	return '已提现' if status == 2	 	
	 	return '提现未成功' if status == -1
	 	return '取消提现' if status == -2
	end

end