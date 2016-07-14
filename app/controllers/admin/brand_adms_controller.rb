#encoding:utf-8
class Admin::BrandAdmsController < Admin::BaseController

  def index
    if params[:scope] == 'unscoped'
        @brands =  Brand.unscoped.order("ordernum asc,slug asc")
    else
        @brands =  Brand.order("ordernum asc,slug asc")
    end
    
    if params[:search]
        key =  params[:search][:key]
        @brands = @brands.where("brand_name like ?","%#{key}%").paginate(:page=>params[:page],:per_page=>20)
    else
        @brands = @brands.paginate(:page=>params[:page],:per_page=>20)
    end
  end

  def new
    @brand  = Brand.new
    @action_url =  admin_brand_adms_path
    @method = :post
  end

  def edit
    @brand = Brand.find(params[:id])
    @action_url =  admin_brand_adm_path(@brand)
    @method = :put
  end

  def create
    @brand  = Brand.new brand_params
    if @brand.save
      redirect_to admin_brand_adms_url
    else
      @action_url =  admin_brand_adms_path
      @method = :post
      render :new
    end
  end

  def update
    @brand  = Brand.find(params[:id])
    if @brand.update_attributes(brand_params)
      redirect_to admin_brand_adms_url
    else
      @action_url =  admin_brand_adm_path(@brand)
      @method = :put
      render :edit
    end
  end

  def destroy
    @brand  = Footer.find(params[:id])
    @brand.destroy
    redirect_to admin_brand_adms_url
  end

   def toggle
    return_url =  request.env["HTTP_REFERER"]
    return_url =  admin_brand_pages_url if return_url.blank?

    @brand = Brand.unscoped.find(params[:id])
    val = @brand.disabled == 'false' ? 'true' : 'false'
    @brand.update_attribute :disabled, val
    redirect_to return_url
  end

  def order
    @brand = Brand.find(params[:id])
    @brand.update_attribute :ordernum,params[:ordernum].to_i
    render :nothing=>true
  end

  def reco
    return_url =  request.env["HTTP_REFERER"]
    return_url =  admin_brand_pages_url if return_url.blank?
    
    @brand = Brand.find(params[:id])
    Brand.where(:reco=>true).update_all :reco=>false
    @brand.update_attribute :reco, true
    redirect_to return_url
  end

  private 
  def brand_params
    params.require(:brand).permit(:brand_name,:status,:brand_logo,:brand_url,:reco,:context,
      :ordernum,:slug,:brand_slogan,:detail_desc,:meta_seo_attributes)
  end
end
