class Templates::OrderTransactionTemplate < Templates::BaseTemplate
  attr_reader :order_transaction

  def initialize(obj = nil)
    @object_type = obj.class
    @order_transaction = obj
  end

  def tags
    return [] if !@order_transaction
    {
      error_message: "error_message",
      transaction_type: "transaction_type",
      time: "time"
    }
  end

  def __error_message
    @order_transaction.error_message if @order_transaction
    false
  end

  def __time
    ApplicationController.helpers.long_date(@order_transaction.created_at) if @order_transaction
  end

  def __transaction_type
    case @order_transaction.transaction_type
    when 'refunded'
      'Refund'
    when 'authorized'
      'Hold'
    when 'captured'
      'Charge'
    end
  end

end
