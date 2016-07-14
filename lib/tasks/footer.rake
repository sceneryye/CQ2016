#encoding:utf-8
namespace :imodec do
	task :footer=>:environment do 
		ac = ActionController::Base.new
		@footer = Footer.first_or_initialize(:title=>"通用页脚",
										   :body=>ac.render_to_string(:partial=>"layouts/footer",:layout=>false))
		@footer.save
	end
end