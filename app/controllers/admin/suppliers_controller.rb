#encoding:utf-8
class Admin::SuppliersController < ApplicationController
	layout 'admin'

	def index
		@suppliers = Supplier.paginate(:page => params[:page], :per_page => 20).order("status DESC,created_at DESC")
	end


	def show

	end

	def new
		@supplier  =  Supplier.new
		@action_url =  admin_suppliers_path
    	@method = :post
	end

	def edit
		@supplier  =  Supplier.find(params[:id])
		@action_url = admin_supplier_path(@supplier)
		@method = :put
	end

	def create
    uploaded_io = params[:license_file]
    if !uploaded_io.blank?
      extension = uploaded_io.original_filename.split('.')
      filename = "#{Time.now.strftime('%Y%m%d%H%M%S')}.#{extension[-1]}"
      filepath = "#{PIC_PATH}/vshop_docs/#{filename}"
      File.open(filepath, 'wb') do |file|
        file.write(uploaded_io.read)
      end
     # params[:supplier].merge!(:license=>"/images/vshop_docs/#{filename}")
    end


    #params[:supplier].merge!(:member_id=>@user.id)
		@supplier = Supplier.new(params[:supplier])
		if @supplier.save
      return_url= params[:return_url]
      if (return_url.blank?)
			redirect_to admin_suppliers_url
      else
        redirect_to "#{return_url}?step=2&id=#{@supplier.id}"
      end
		else
			render :new
		end
		
	end

	def update
    #return render :text=>params[:supplier][:layout]
		@supplier = Supplier.find(params[:id])
		
		if @supplier.update_attributes(params[:supplier])
      return_url= params[:return_url]
      if return_url
        redirect_to "#{return_url}?step=3"
      else
        redirect_to admin_suppliers_url
      end

		else
			@action_url = admin_supplier_path(@supplier)
			@method = :put
			render :edit
		end
	end



	def destroy
		@supplier = Supplier.find(params[:id])
		@supplier.destroy

		redirect_to admin_suppliers_url
  end

  def update_state
    @supplier = Supplier.find(params[:supplier_id])
      unless @supplier.status=="1"
        Supplier.where(:id=>params[:supplier_id]).update(params[:supplier_id],{:status=>1})
       end

    @account=Account.find(params[:user_id])
    @account.update_attribute(:supplier_id,params[:supplier_id])
    if @account.account_type=="shopadmin"
       @account.update_attribute(:account_type,"member")

    end
    @manager=Manager.find_by_user_id(params[:user_id])
    unless @manager
     Manager.new do |sv|
        sv.user_id = @account.account_id
        sv.status = "1"
        sv.name = @supplier.name
    end.save
    end

    redirect_to "/admin/suppliers"  ,:notice=>'更新成功!'
  end

   private

  def supplier_params
      params.require(:supplier).permit(:menu)
    end

end