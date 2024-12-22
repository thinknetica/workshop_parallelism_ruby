class AddIndexToOrders < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def change
    add_index :orders, :current_status, where: "current_status = 'pending'", algorithm: :concurrently
  end
end
