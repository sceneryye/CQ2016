class Address < ActiveRecord::Base
	self.table_name = "sdb_imodec_addresses"
	belongs_to :brand, :polymorphic=>true

	

	geocoded_by :name
	after_validation :geocode

	def province
		self.name.slice(0,2)
	end
end