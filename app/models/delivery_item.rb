class DeliveryItem < ActiveRecord::Base
	self.table_name = 'sdb_b2c_delivery_items'
	
	belongs_to :delivery, :foreign_key=>"delivery_id"

	belongs_to :product, :foreign_key=>"product_id"
	
end