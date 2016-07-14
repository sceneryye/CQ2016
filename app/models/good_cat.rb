class GoodCat < ActiveRecord::Base
  self.table_name = "goods_cat"
  self.primary_key = 'cat_id'
  has_many :goods,->{where(marketable:'true')},:foreign_key=> "cat_id"

  has_many :good_cats,:foreign_key=>"parent_id",:class_name=>"GoodCat"
  belongs_to :parent_cat,  :foreign_key=>"parent_id", :class_name=>"GoodCatgg"

  has_one :seo,->{where(mr_id:4 )}, :foreign_key=>:pk

  include Metable

  def all_goods( conditions={} )
    @all_goods = []

    conditions.each do |key,val|
      raise "Field `#{key}`  is existence" unless Good.attribute_names.include?(key.to_s)
    end if conditions.present?

    if self.good_cats.blank?
      @all_goods += self.goods.where(conditions).order("d_order desc").to_a
    else
      self.good_cats.each { |cat| @all_goods += cat.all_goods(conditions) }
    end

    @all_goods

  end

  def child_cats
  	childs = GoodCat.where(:parent_id=>self.cat_id)
  end

  def self.top_cats
    cats = GoodCat.where(:parent_id=>0).where('sell=true or future=true or agent=true')
  end

  def start_blank
  	num = self.cat_path.split(",").length
  	str =""
  	num.times.each do 
  		str = str + "--"
  	end
  	return str
  end

  def cat_path_rep
  	return self.cat_path.gsub(",","-")
  end

  def cat_path_deep
  	num = self.cat_path.split(",").length
  end

  def has_leaf?
  	count = GoodCat.where(:parent_id=>self.cat_id).count
  	if count > 0
  		return true
  	else
  		return false
  	end
  end
end
