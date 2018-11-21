class AddRawResponseToOrderTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :order_transactions, :raw_api_response, :jsonb
  end
end
