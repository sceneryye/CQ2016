#encoding:utf-8
class Store::CartController < ApplicationController
	before_filter :find_user
	layout 'application'

  	def index

  	end

	
	def add

		specs = params[:product].delete(:specs)
		# customs = params[:product].delete(:customs)
		quantity = cart_params[:quantity]
		goods_id = cart_params[:goods_id]
	 #    if quantity.blank? || quantity ==0
	 #       quantity=1
	 #    end
	   
    
    # product_id = specs.collect do |spec_value_id|
		# 	GoodSpec.where(params[:product].merge(:spec_value_id=>spec_value_id)).pluck(:product_id)
		# end.inject(:&).first

		@good = Good.find_by_goods_id(goods_id)
		# @product  =  @good.products.select do |p|
		# 	p.spec_desc["spec_value_id"].values.map{ |x| x.to_s }.sort == specs.sort
		# end.first
	    if specs[0].empty?
	      @product = @good.products.first
	    else
	      @product  =  @good.products.select do |p|
	        p.good_specs.pluck(:spec_value_id).map{ |x| x.to_s }.sort == specs.sort
	      end.first
	    end

		if signed_in?
			member_id = @user.member_id
			member_ident = Digest::MD5.hexdigest(@user.member_id.to_s)
		else
			member_id = -1
			member_ident = @m_id
		end

		@cart = Cart.where(:obj_ident=>"goods_#{goods_id}_#{@product.product_id}",
									  :member_ident=>member_ident).first_or_initialize do |cart|
			cart.obj_type = "goods"
			cart.quantity = quantity
			cart.time = Time.now.to_i
			cart.member_id = member_id
		end

		if @cart.new_record?
			@cart.save
		else
			Cart.where(:obj_ident=>@cart.obj_ident,:member_ident=>member_ident).update_all(:quantity=>@cart.quantity+quantity.to_i)
			@cart.quantity = (@cart.quantity+1)
		end
		
		find_cart!
        redirect_to cart_index_path
		#rescue
			#render :text=>"add failed"
	end

 
	def update
		quantity = params[:quantity]
		@line_items.where(:obj_ident=>params[:id]).update_all(:quantity=>quantity)
		@line_item  = @line_items.where(:obj_ident=>params[:id]).first
		find_cart!
		render "update"
	end

	def destroy
		_type, goods_id, product_id = params[:id].split('_')
		@line_items.where(:obj_ident=>params[:id]).delete_all
		@user.custom_specs.where(:product_id=>product_id).delete_all if signed_in?

		find_cart!

  		render "destroy"
	end

	private
	def cart_params
    	params.require(:product).permit(:quantity,:goods_id,:type_id)
  	end
end
