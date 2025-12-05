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

    begin
        # Create payment record
        order.create_payment!(
            payment_id: payment_id,
            status: 'succeeded',
            amount: amount,
            payment_method: payment_method,
            processed_at: Time.current
        )

        # Confirm the order
        OrderService.confirm_order(order)
    rescue InsufficientInventoryError => e
        logger.error "Insufficient inventory for order #{order.order_number}: #{e.message}"
        # Cancel order and trigger refund process
        OrderService.cancel_order(order)
        raise
    end

    order
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

    # Create failed payment record (always persist for audit trail)
    order.create_payment!(
      payment_id: payment_id,
      status: 'failed',
      amount: amount,
      payment_method: payment_method,
      processed_at: Time.current
    )

    # Cancel the order
    OrderService.cancel_order(order)

  end
end
