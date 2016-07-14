class CouponDownload < ActiveRecord::Base
	self.table_name = "sdb_imodec_coupon_downloads"

	

	belongs_to :user,:foreign_key => "member_id"
	belongs_to :offline_coupon


	

end