class ChangeFieldTypeToHomes < ActiveRecord::Migration
  def change
  	change_column :sdb_imodec_homes,:sliders,:text
  	change_column :sdb_imodec_homes,:keywords,:text
  	change_column :sdb_imodec_homes,:pops,:text
  	change_column :sdb_imodec_homes,:clothing,:text
  	change_column :sdb_imodec_homes,:bags,:text
  end


  def connection
  	@connection =  Base.connection
  end

end
