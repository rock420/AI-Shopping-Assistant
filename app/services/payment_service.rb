class PaymentService
  # Processes a successful payment webhook
  #
  # @param order [Order] The order to process payment for
  # @param payment_id [String] External payment provider ID
  # @param amount [BigDecimal] Payment amount
  # @param payment_method [String] payment method
  # @param payment_metadata [Hash] metdata related to payment
  # @raise [OrderExpiredError] if order has expired
  # @raise [InsufficientInventoryError] if insufficient inventory
  # @raise [ArgumentError] if validation fails
  def self.process_success(order, payment_id, amount, payment_method, payment_metadata)
    raise ArgumentError, 'Order cannot be nil' if order.nil?
    raise ArgumentError, 'Payment ID cannot be blank' if payment_id.blank?

    # Verify amount matches
    if amount.to_f != order.total_amount.to_f
      raise ArgumentError, "Payment amount mismatch. Expected: #{order.total_amount}, Got: #{amount}"
    end

    payment = nil
    
    # Create payment record
    begin
      payment = order.create_payment!(
        payment_id: payment_id,
        status: 'succeeded',
        amount: amount,
        payment_method: payment_method,
        processed_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique
      Rails.logger.info "Payment #{payment_id} already exists for order #{order.order_number}"
      return order.reload
    end

    # Confirm the order
    begin
      # Confirm the order (fulfills inventory)
      OrderService.confirm_order(order)
      notify_agent_of_payment_status(order, payment_metadata, true)
    rescue OrderExpiredError => e
      Rails.logger.error "Order #{order.order_number} expired: #{e.message}"
      handle_order_confirmation_failure(order, payment, 'Order expired')
      raise
    rescue ArgumentError => e
      # Order in invalid state (e.g., already cancelled)
      Rails.logger.error "Cannot confirm order #{order.order_number}: #{e.message}"
      handle_order_confirmation_failure(order, payment, e.message)
      raise
    rescue StandardError => e
      # Unexpected error - log and refund
      Rails.logger.error "Unexpected error confirming order #{order.order_number}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      handle_order_confirmation_failure(order, payment, 'System error')
      raise
    end
  end

  # Processes a failed payment webhook
  #
  # @param order [Order] The order with failed payment
  # @param payment_id [String] External payment provider ID
  # @param amount [BigDecimal] Payment amount
  # @param payment_method [String] payment method
  # @param payment_metadata [Hash] metdata related to payment
  # @raise [ArgumentError] if validation fails
  def self.process_failure(order, payment_id, amount, payment_method, payment_metadata)
    raise ArgumentError, 'Order cannot be nil' if order.nil?
    raise ArgumentError, 'Payment ID cannot be blank' if payment_id.blank?

    # Create payment record
    begin
      order.create_payment!(
        payment_id: payment_id,
        status: 'failed',
        amount: amount,
        payment_method: payment_method,
        processed_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique
      # Payment already exists
      Rails.logger.info "Payment #{payment_id} already exists for order #{order.order_number}"
      return order.reload
    end

    begin
      OrderService.cancel_order(order)
    rescue  ArgumentError => e
      Rails.logger.error "Cannot cancel order #{order.order_number}: #{e.message}"
    rescue StandardError => e
      # Unexpected error
      Rails.logger.error "Unexpected error cancelling order #{order.order_number}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      notify_agent_of_payment_status(order, payment_metadata, false)
    end
  end

  private

  # Handles order confirmation failure by cancelling order
  #
  # @param order [Order] The order that failed to confirm
  # @param payment [Payment] The payment record
  # @param reason [String] Reason for failure
  # @param conversation_id [String] Optional converation id if the order is part of a conversation
  def self.handle_order_confirmation_failure(order, payment, reason, conversation_id)
    # Cancel order if still pending
    if order.status == 'pending'
      OrderService.cancel_order(order)
    end
    notify_agent_of_payment_status(order, payment_metadata, false)

    # TODO: Trigger refund process with payment provider
  rescue StandardError => e
    Rails.logger.error "CRITICAL: Failed to handle order confirmation failure for #{order.order_number}: #{e.message}"
    # TODO: Send alert to ops team
  end

  # Notifies the agent about payment status for an order in a conversation
  #
  # @param order [Order] The order status to be notified
  # @param payment_metadata [Hash] metdata related to payment
  # @param isOrderConfirmed [Boolean] Whether the order was successfully confirmed
  def self.notify_agent_of_payment_status(order, payment_metadata, isOrderConfirmed)
    if payment_metadata[:conversation_id].nil?
      return
    end
    conversation_id = payment_metadata[:conversation_id]
    Rails.logger.info "Notifying agent for conversation_id: #{conversation_id}"

    conversation = Conversation.find_by(id: conversation_id)
    if conversation.nil?
      Rails.logger.error "Conversation not found for conversation_id: #{conversation_id}"
      return
    end

    if isOrderConfirmed == true
      conversation.messages << build_success_system_message(order)
    else
      conversation.messages << build_failure_system_message(order)
    end
    conversation.save!

    # We have two ways to get a response from agent based on the payment event ->
    # 1. Hardcode agent message - we can add a hardcoded message on behalf of the agent to the conversation
    # 2. Asynchronously trigger cartAgent to generate a response based on system message -> we would need to use 
    # some Queue to process it asynchronously as we shouldn't block the webhook call
    #
    # Though both the approaches are good, each have their own pros and cons. For this project, I am going ahead
    # with synchronous version of approach 2 to give a more natural, contextual response.
    
    begin
      context = {
        conversation_id: conversation_id,
        session_id: conversation.session_id,
        messages: conversation.messages
      }
      CartAgent.instance.run_stream("", conversation.session_id, context: context) do |chunk|
        case chunk[:type]
        when "done"
          if chunk[:ui_context]
            conversation.messages.last["ui_context"] = chunk[:ui_context]
          end
          conversation.save!
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error notifying agent of payment status: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def self.build_success_system_message(order)
    {  
      "role" => "system", 
      "content" => <<~MSG 
        PAYMENT COMPLETED SUCCESSFULLY
        - Order: #{order.order_number}
        - Amount: $#{order.total_amount}
        - Status: Order confirmed
        
        Inform the user their payment succeeded and order is confirmed.
        Fetch the order details first and then show the order confirmation UI based on that data.
        Reference any relevant details from the conversation (e.g., delivery preferences, special requests).
        Make it engaging to help continue their shopping or suggest more products based on the purchase 
      MSG
    }
  end

  def self.build_failure_system_message(order)
    {
      "role" => "system",
      "content" => <<~MSG.strip
        PAYMENT FAILED
        - Order: #{order.order_number}
        - Amount: $#{order.total_amount}
        - Status: Order cancelled

        Inform the user their payment failed and order was cancelled.
        Offer to help them try again with a different payment method.
      MSG
    }
  end
end
