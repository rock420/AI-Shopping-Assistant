class PaymentService
  # Processes a successful payment webhook
  #
  # @param order [Order] The order to process payment for
  # @param payment_id [String] External payment provider ID
  # @param amount [BigDecimal] Payment amount
  # @param payment_method [String] payment method
  # @raise [OrderExpiredError] if order has expired
  # @raise [InsufficientInventoryError] if insufficient inventory
  # @raise [ArgumentError] if validation fails
  def self.process_success(order, payment_id, amount, payment_method)
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
  # @raise [ArgumentError] if validation fails
  def self.process_failure(order, payment_id, amount, payment_method)
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
    end
  end

  private

  # Handles order confirmation failure by cancelling order
  #
  # @param order [Order] The order that failed to confirm
  # @param payment [Payment] The payment record
  # @param reason [String] Reason for failure
  def self.handle_order_confirmation_failure(order, payment, reason)
    # Cancel order if still pending
    if order.status == 'pending'
      OrderService.cancel_order(order)
    end
    
    # TODO: Trigger refund process with payment provider
  rescue StandardError => e
    Rails.logger.error "CRITICAL: Failed to handle order confirmation failure for #{order.order_number}: #{e.message}"
    # TODO: Send alert to ops team
  end
end
