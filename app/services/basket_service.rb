class BasketService
  # Adds an item to the basket with inventory validation.
  #
  # @param basket [Basket] The basket to add to
  # @param product [Product] The product to add
  # @param quantity [Integer] Quantity to add
  # @return [BasketItem] The created or updated basket item
  # @raise [InsufficientInventoryError] if insufficient inventory
  def self.add_item(basket, product, quantity)
    raise ArgumentError, 'Quantity must be greater than 0' if quantity <= 0

    # Find existing item to calculate total quantity needed
    existing_item = basket.basket_items.find_or_initialize_by(product: product)
    total_quantity_needed = existing_item.persisted? ? existing_item.quantity + quantity : quantity
    
    # Validate inventory before adding
    validate_inventory(product, total_quantity_needed)

    # Add to basket
    basket.add_product(product, quantity, existing_item)
  rescue InsufficientInventoryError
    raise
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Product: #{product.name} is not found"
    raise ArgumentError, e.message
  end

  # Removes an item from the basket.
  #
  # @param basket [Basket] The basket to remove from
  # @param product [Product] The product to remove
  # @param quantity [Integer, nil] Quantity to remove (nil = remove all)
  # @raise [ArgumentError] if item not in basket
  # @return [void]
  def self.remove_item(basket, product, quantity = nil)
    removed = basket.remove_product(product, quantity)
    raise ArgumentError, 'Item not in basket' unless removed
  end

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

  # Clears all items from the basket.
  #
  # @param basket [Basket] The basket to clear
  # @return [void]
  def self.clear_basket(basket)
    basket.clear
  end

  # Updates the quantity of an existing basket item with inventory validation.
  #
  # @param basket [Basket] The basket containing the item
  # @param product [Product] The product to update
  # @param new_quantity [Integer] New quantity
  # @return [BasketItem] The updated basket item
  # @raise [InsufficientInventoryError] if insufficient inventory
  # @raise [ArgumentError] if item not in basket
  def self.update_item_quantity(basket, product, new_quantity)
    raise ArgumentError, 'Quantity must be greater than 0' if new_quantity <= 0

    basket_item = basket.basket_items.find_by(product_id: product.id)
    raise ArgumentError, 'Item not in basket' unless basket_item

    # Validate inventory for the new quantity
    validate_inventory(product, new_quantity)

    basket_item.update!(quantity: new_quantity)
    basket_item
  rescue InsufficientInventoryError
    raise
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Product: #{product.name} is not found"
    raise ArgumentError, e.message
  end
end
