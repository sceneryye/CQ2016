#encoding:utf-8
class Admin::GoodsLabelsController < Admin::BaseController

  def index
    @labels = GoodLabel.paginate(:page=>params[:page],:per_page=>20)
  end

  def edit
    @goods_label = GoodLabel.find(params[:id])
  end

  def new
    @goods_label = GoodLabel.new
  end

  def create
    @goods_label = GoodLabel.new
    @goods_label.tag_name = params[:good_label][:tag_name]
    @goods_label.tag_bgcolor = params[:color]
    @goods_label.app_id = "b2c"
    @goods_label.save
    redirect_to admin_goods_labels_path
  end

  def updateLabel
    @goods_label = GoodLabel.find(params[:id])
    @goods_label.tag_name = params[:good_label][:tag_name]
    @goods_label.tag_bgcolor = params[:color]
    @goods_label.save
    redirect_to admin_goods_labels_path
  end


  def destroy
    @goodsLabel = GoodLabel.find(params[:id])
    @goodsLabel.destroy
    redirect_to admin_goods_labels_path
  end
end
