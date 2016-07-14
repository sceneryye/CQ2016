class AddMemberIdToGoods < ActiveRecord::Migration
  def change
    add_column :sdb_b2c_goods, :member_id, :int      ###记录发布人
  end

  def connection
    @connection = Base.connection
  end
end
