#encoding:utf-8
class CardAllinpayTxnlog < ActiveRecord::Base
	self.table_name = "card_allinpay_txnlogs"
	self.primary_key = 'int_txn_seq_id'
  	
  	# belongs_to :card
  	# belongs_to :rebate
end