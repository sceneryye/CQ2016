class CardLog < ActiveRecord::Base
	self.table_name = "card_logs"
  	
  	belongs_to :card, :foreign_key=>"card_id"

  	belongs_to :account,:foreign_key=>"member_id"

end