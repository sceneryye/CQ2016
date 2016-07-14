#encoding:utf-8
class Comment < ActiveRecord::Base
	self.table_name = "sdb_imodec_comments"
	
	belongs_to :good, :foreign_key=>"commentable_id"
	belongs_to :user, :foreign_key=>"member_id"

	validates_presence_of :content, :message=>"评论内容不能为空"
end