#encoding:utf-8
class OrderOffline < ActiveRecord::Base

  self.table_name = "order_offlines"

  belongs_to :card,:foreign_key=>"card_id"

end