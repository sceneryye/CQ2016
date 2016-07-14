#encoding:utf-8
class Admin::CardTradingsController < Admin::BaseController
	before_filter :require_permission!

	def new
		@card_trading =CardTrading.new
	end


	def create

		@card = Card.find_by_no(card_trading_params[:card_no])
		# return render text: @card.present?
		if @card.present?
			@card_trading = CardTrading.new card_trading_params do |trading|
				trading.card_id = @card.id
				trading.trading_type = 1
			end
			if @card_trading.save
				if @card.card_type=='B'
		    		rate = 0.1
		    		parent_rate =0.15
		    	else
		    		rate = 0.15
		    	end
	    		@rebate = Rebate.new do |rebate|
		    		rebate.member_id = @card.member_card.member_id
		    		rebate.card_id = @card.id
		    		rebate.card_trading_id = @card_trading.id
		    		rebate.rate = rate
		    		rebate.amount = @card_trading.amount * rate 
		    		rebate.rebate_type = '0'
		    	end

		    	if @rebate.save && @card.card_type=='B'
		    		@rebate = Rebate.new do |rebate|
			    		rebate.member_id = @card.parent_card.member_card.member_id
			    		rebate.card_id = @card.id
			    		rebate.card_trading_id = @card_trading.id
			    		rebate.rate = parent_rate
			    		rebate.amount = @card_trading.amount * parent_rate 
			    		rebate.rebate_type = '1'
			    	end
			    	@rebate.save!
			    end

				return redirect_to admin_card_tradings_path
			else
				return render 'new'
			end
		else
			render 'new', notice: '卡号不存在'
		end

	end
	  
	def index
	    @type = params[:type].to_i
		if @type.blank?
			@type = 0		
		end
		if @type == 0
			@online='disabled'
		else
			@others = 'disabled'
		end	

		@card_tradings =   CardTrading.where(trading_type: @type)	

	    @card_tradings_total = @card_tradings.count
	    @card_tradings = @card_tradings.paginate(:page=>params[:page],:per_page=>20)	

	end

	private
	def card_trading_params
		params.require(:card_trading).permit(:card_no,:amount,:trading_time,:location)
	end

	
end
