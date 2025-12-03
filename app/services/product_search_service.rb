class ProductSearchService
  # Searches products based on provided filters
  #
  # @param filters [Hash] Search filters
  # @option filters [String] :query Text search on name and description
  # @option filters [Float] :min_price Minimum price filter
  # @option filters [Float] :max_price Maximum price filter
  # @option filters [Hash] :attributes JSONB attribute filters (color, size, category, etc.)
  # @return [ActiveRecord::Relation] Filtered products
  def search(filters)
    products = Product.where('inventory_quantity > 0')
    
    Rails.logger.info "Apply product search filters: #{filters}"
    products = apply_text_search(products, filters[:query]) if filters[:query].present?
    products = apply_price_range(products, filters[:min_price], filters[:max_price]) if filters[:min_price] || filters[:max_price]
    products = apply_attribute_filters(products, filters[:attributes]) if filters[:attributes].present?
    
    products.order(created_at: :desc)
  end
  
  private
  
  # Applies text search on product name and description
  #
  # @param products [ActiveRecord::Relation] Current product scope
  # @param query [String] Search query
  # @return [ActiveRecord::Relation] Filtered products
  def apply_text_search(products, query)
    return products if query.blank?
    
    products.where(
      'name ILIKE :query OR description ILIKE :query',
      query: "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    )
  end
  
  # Applies price range filtering
  #
  # @param products [ActiveRecord::Relation] Current product scope
  # @param min_price [Float, nil] Minimum price
  # @param max_price [Float, nil] Maximum price
  # @return [ActiveRecord::Relation] Filtered products
  def apply_price_range(products, min_price, max_price)
    products = products.where('price >= ?', min_price) if min_price
    products = products.where('price <= ?', max_price) if max_price
    products
  end
  
  # Applies JSONB attribute filtering
  #
  # @param products [ActiveRecord::Relation] Current product scope
  # @param attributes [Hash] Attribute filters (e.g., { color: 'red', size: 'medium' })
  # @return [ActiveRecord::Relation] Filtered products
  def apply_attribute_filters(products, attributes)
    return products if attributes.blank?
    
    attributes.each do |key, value|
      next if value.blank?
      
      if value.is_a?(Array)
        # Array contains any of the values
        products = products.where(
          "product_attributes->? ?| array[:values]",
          key.to_s,
          values: value
        )
      else
        # Exact match (case-insensitive)
        products = products.where(
          "LOWER(product_attributes->>?) = LOWER(?)",
          key.to_s,
          value.to_s
        )
      end
    end
    
    products
  end
  
end
