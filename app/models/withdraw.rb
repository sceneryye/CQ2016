class Withdraw < ActiveRecord::Base

	 belongs_to :users, :foreign_key=>"member_id"
	 has_many :rebates
	 belongs_to :card_trading

end