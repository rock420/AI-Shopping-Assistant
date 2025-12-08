class OrderService
  # Creates an order from a basket
  #
  # @param basket [Basket] The basket to create an order from
  # @return [Order] The created order with order_items loaded
  # @raise [InsufficientInventoryError] if insufficient inventory
  # @raise [ActiveRecord::RecordInvalid] if validation fails
  def self.create_from_basket(basket)
    raise ArgumentError, 'Basket cannot be nil' if basket.nil?
    
    if basket.basket_items.empty?
      basket.errors.add(:base, 'Basket is empty')
      raise ActiveRecord::RecordInvalid.new(basket)
    end

    order = nil

    ActiveRecord::Base.transaction do
      # Load basket items once with products
      basket_items = basket.basket_items.includes(:product).order(:product_id)

      # reserve inventory for all items
      basket_items.each do |basket_item|
        basket_item.product.reserve_inventory!(basket_item.quantity)
      end

      # Calculate total
      total_amount = basket_items.sum { |item| item.line_total }

      # create pending order
      order = Order.new(
        session_id: basket.session_id,
        total_amount: total_amount,
        status: 'pending'
      )

      # Create order items
      basket_items.each do |basket_item|
        order.order_items.build(
          product_id: basket_item.product_id,
          product_name: basket_item.product.name,
          quantity: basket_item.quantity,
          price: basket_item.price_at_addition
        )
      end

      # Save order and order_items
      order.save!
    end

    order
  end

  # Confirms a pending order by deducting inventory and clearing the basket
  #
  # @param order [Order] The pending order to confirm
  # @return [Order] The confirmed order
  # @raise [OrderExpiredError] if order has expired
  # @raise [InsufficientInventoryError] if insufficient inventory
  # @raise [ActiveRecord::RecordInvalid] if validation fails
  def self.confirm_order(order)
    raise ArgumentError, 'Order cannot be nil' if order.nil?
    if order.status == 'completed'
          Rails.logger.info "Order #{order.order_number} already completed"
          return order
    end
    raise OrderExpiredError.new(order) if order.expired?
    raise ArgumentError, 'Order must be pending' unless order.status == 'pending'

    ActiveRecord::Base.transaction do
      # Atomic check-and-update: Only update status if currently pending
      updated = order.mark_as_completed!
      
      unless updated
        if order.status == 'completed'
          Rails.logger.info "Order #{order.order_number} already completed"
          return order
        else
          raise ArgumentError, "Cannot confirm order #{order.order_number} with status: #{order.status}"
        end
      end

      # Load order items with products
      order_items = order.order_items.includes(:product).order(:product_id)

      # Fulfill reserved inventory atomically for all items
      order_items.each do |order_item|
        order_item.product.fulfill_reserved_inventory!(order_item.quantity)
      end
    end

    begin:
      # Clear the basket associated with this order
      basket = Basket.find_by(session_id: order.session_id)
      basket&.basket_items&.delete_all
    rescue => e
      Rails.logger.error "Failed to clear basket for order #{order.order_number}: #{e.message}"
    end

    order
  end

  # Cancels a pending order
  #
  # @param order [Order] The pending order to cancel
  # @return [Order] The cancelled order
  # @raise [ActiveRecord::RecordInvalid] if validation fails
  def self.cancel_order(order)
    raise ArgumentError, 'Order cannot be nil' if order.nil?
    if order.status == 'cancelled'
      Rails.logger.info "Order #{order.order_number} already cancelled"
      return order
    end
    raise ArgumentError, 'Only pending orders can be cancelled' unless order.status == 'pending'

    ActiveRecord::Base.transaction do
      # Atomic check-and-update: Only update status if currently pending
      updated = order.mark_as_cancelled!
      
      unless updated
        if order.status == 'cancelled'
          Rails.logger.info "Order #{order.order_number} already cancelled"
          return order
        else
          raise ArgumentError, "Cannot cancel order #{order.order_number} with status: #{order.status}"
        end
      end

      # Load order items with products
      order_items = order.order_items.includes(:product).order(:product_id)

      # release reserve inventory atomically for all items
      order_items.each do |order_item|
        order_item.product.release_inventory!(order_item.quantity)
      end
    end

    order
  end

  private


  # Validates that sufficient inventory is available for the requested quantity.
  #
  # @param product [Product] The product to validate
  # @param quantity [Integer] Requested quantity
  # @raise [InsufficientInventoryError] if insufficient inventory
  # @return [Boolean] true if sufficient inventory
  def self.validate_inventory(product, quantity)
    if product.inventory_quantity < quantity
      Rails.logger.error "Insufficient inventory for #{product.name}. Available: #{product.inventory_quantity}, Requested: #{quantity}"
      raise InsufficientInventoryError.new(
            product.name,
            product.inventory_quantity,
            quantity
        )
    end
    true
  end

end
