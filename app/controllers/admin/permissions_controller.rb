#encoding:utf-8
class Admin::PermissionsController < Admin::BaseController
  def index
    @managers = Manager.all
  end

  def new
  end

  def update
   
    manager_id = params[:id]

    @permission = Permission.where(:manager_id=>manager_id).first
    if @permission
      @permission.update_attributes(:rights=>params[:permission].to_json)
    else
      Permission.create(:manager_id=>manager_id,:rights=>params[:permission].to_json)
    end
    
    redirect_to edit_admin_permission_path(params[:id]),:notice=>'权限保存成功!'
  end

  def edit
    @manager = Manager.find(params[:id])
    @resources = Resource.where(:parent_id=>nil)
  end
end
