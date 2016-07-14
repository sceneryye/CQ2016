#encoding:utf-8
class Store::GoodsController < ApplicationController
  layout 'application'

  skip_before_filter :authorize_user!,:only=>[:price]
  before_filter :find_user, :except=>[:price]
  skip_before_filter :find_path_seo, :find_cart!, :only=>[:newest]
  before_filter :find_tags, :only=>[:cheuksgroup,:newest]
  
  def coupon_goods
    @coupon_id  = params[:coupon_id]
    @coupon = NewCoupon.find_by_id(@coupon_id)
    bn =  @coupon.condition_val.to_s.gsub('[','(').gsub(']',')')
    @goods = Good.where("bn in #{bn}").paginate(:page=>params[:page], :per_page=>18)
    render :layout=>'coupons'
  end

  def show
    @coupon_id = params[:coupon_id]
    @wechat_user=params[:wechatuser]

    @good = Good.includes(:specs,:spec_values,:cat).where(:bn=>params[:id]).first

    return render "not_find_good",:layout=>"new_store" unless @good

    tag_name = params[:tag]
    @tag = TagName.find_by_tag_name(tag_name)

    @cat = @good.cat

    @recommend_goods = []
    if @cat.goods.size >= 4
      @recommend_goods =  @cat.goods.where("goods_id <> ?", @good.goods_id).order("goods_id desc").limit(4)
    else
      @recommend_goods += @cat.goods.where("goods_id <> ?", @good.goods_id).limit(4).to_a
      @recommend_goods += @cat.parent_cat.all_goods.select{|good| good.goods_id != @good.goods_id }[0,4-@recommend_goods.size] if @cat.parent_cat && @recommend_goods.size < 4
      @recommend_goods.compact!
      if @cat.parent_cat && @recommend_goods.size < 4
        count = @recommend_goods.size
        @recommend_goods += @cat.parent_cat.all_goods.select{|good| good.goods_id != @good.goods_id }[0,4-count]
      end
    end
    if @coupon_id
       @current_lv_1='plan-price'
      return  render :layout=>'coupons'
    end
    if @user
      case @user.member_lv_id
      when 1
        @current_lv_1 ='plan-price'
      when 2
         @current_lv_2 ='plan-price'
      when 3
         @current_lv_3='plan-price'
      end
    end
    
  end

  def index
      tag_name  = params[:tag]
      @tag = Teg.find_by_tag_name(tag_name)
       if @tag
              order = params[:order]
              order_string = "goods_id desc"
              if order.present?
                order_string = order.split("-").join(" ")
              end
              @goods = @tag.goods.order(order_string).paginate(:page=>params[:page], :per_page=>18)
       else
            redirect_to  newest_goods_url
       end
  end

  def newin
      @line_items =  @user.line_items if @user
      @tag = TagName.where('tag_name rlike ?','z[0-9]{4}').last
      if @tag
          if params[:page].nil? || params[:page].to_i <= 1
              @goods = @tag.goods.paginate(:page=>1, :per_page=>10).order("uptime desc").to_a
              # render "index"
              respond_to do |format|
                format.mobile  { render(:layout => "layouts/store", :action => "index") }
                format.html { render(:layout => "layouts/store", :action => "index") }
              end
          
          else
              @goods = @tag.goods.paginate(:page=>params[:page], :per_page=>10).order("uptime desc").to_a
              render "scroll_loading"
          end
      end

  end

  def newest
      @tag = @tags.first
      if @tag
          order = params[:order]
          order_string = "goods_id desc"
          if order.present?
            order_string = order.split("-").join(" ")
          end
          @goods = @tag.goods.order(order_string).paginate(:page=>params[:page], :per_page=>18)
      end
      respond_to do |format|
          format.html { render "index" }
      end
  end

  def suits
      @line_items =  @user.line_items if @user
      @goods = Good.suits.paginate(:page=>1, :per_page=>10).order("uptime desc")
      
      respond_to do |format|
        format.html { render :layout=>"standard" }
        format.js
      end
  end

  def more_suits
      @goods = Good.suits.paginate(:page=>params[:page], :per_page=>10).order("uptime desc")
      render :layout=>nil
  end


  def more
    @tags = TagName.where('tag_name rlike ?','z[0-9]{4}').order("tag_id desc").select { |t| t&&t.tag_ext&&!t.tag_ext.disabled }.paginate(params[:page]||1,9)
    render :layout=>'standard'
  end



  def fav
      @good = Good.find(params[:id])
      @fav = Favorite.where(goods_id:params[:id], member_id:@user.member_id)
      if @fav.size==0
        @fav =  Favorite.new do |fav|
            fav.goods_id = params[:id]
            fav.member_id = @user.member_id
            fav.status = 'ready'
            fav.create_time = Time.now.to_i
            fav.disabled =  'false'
            fav.type = 'fav'
            fav.object_type = "goods"
        end
        @fav.save
      end
      render "fav"
  end

  def unfav
      @good = Good.find(params[:id])
      Favorite.where(:member_id=>@user.member_id, :goods_id=>params[:id]).delete_all
      render "unfav"
  end

  def price
      @good = Good.includes(:products,:good_type_specs).find(params[:id])
      
      return render(:nothing=>true) unless request.xhr?
      spec_type_count = @good.good_type_specs.blank? ? @good.spec_desc.size  : @good.good_type_specs.size
      return render(:nothing=>true)  if params[:spec_values].size != spec_type_count

      @product  =  @good.products.select do |p|
        p.good_specs.pluck(:spec_value_id).map{ |x| x.to_s }.sort == params[:spec_values].sort || p.spec_desc["spec_value_id"].values.map{ |x| x.to_s }.sort == params[:spec_values].sort
      end.first
      
      render :json=>{ :price=>@product.price,:store=>@product.p_store }
  end


  private 
    def more_arrivals
        except_tag = ''
        except_tag = params[:tag] if params[:tag].present?
        except_tag = TagName.where('tag_name rlike ?','z[0-9]{4}').last.tag_name if action_name == "newest"

        @tags ||= TagName.where('tag_name rlike ? and tag_name <> ?','z[0-9]{4}',except_tag).order("tag_id desc").limit(6)
    
    end

    def more_products
        except_tag = ''
        except_tag = params[:tag] if params[:tag].present?
        except_tag = TagName.where('tag_name rlike ?','z[0-9]{4}').last.tag_name if action_name == "newest"

        @tags ||= TagName.where('tag_name rlike ? and tag_name <> ?','z[0-9]{4}',except_tag).order("tag_id desc")
    end

    def find_search_key
        config = Config.find_by_key('search_key')
        @search_key =  config.value  if config
    end

    def find_tags
        @tags =  Teg.includes(:tag_ext).where('tag_name rlike ?','z[0-9]{4}').order("tag_id desc").limit(20)
    end



end
