module Api
  class BasketsController < ApplicationController
    before_action :set_basket, only: [:show, :destroy]
    before_action :set_basket_and_product, only: [:add_item, :update_item, :destroy_item]

    # GET /api/baskets/:session_id
    def show
      render json: basket_response(@basket)
    end

    # POST /api/baskets/:session_id/items
    def add_item
      quantity = params[:quantity].to_i

      BasketService.add_item(@basket, @product, quantity)

      render json: basket_response(@basket), status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    rescue InsufficientInventoryError => e
      render json: { 
        error: e.message, 
        available: e.available 
      }, status: :unprocessable_entity
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # PATCH /api/baskets/:session_id/items/:product_id
    def update_item
      new_quantity = params[:quantity].to_i

      BasketService.update_item_quantity(@basket, @product, new_quantity)

      render json: basket_response(@basket)
    rescue InsufficientInventoryError => e
      render json: { 
        error: e.message, 
        available: e.available 
      }, status: :unprocessable_entity
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # DELETE /api/baskets/:session_id/items/:product_id
    # Optional query param: ?quantity=N - if provided, decrements by N; if omitted, removes entire item
    def destroy_item
      quantity = params[:quantity]&.to_i

      BasketService.remove_item(@basket, @product, quantity)

      render json: basket_response(@basket)
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # DELETE /api/baskets/:session_id
    def destroy
      BasketService.clear_basket(@basket)

      render json: basket_response(@basket)
    end

    private

    def set_basket
      @basket = Basket.find_or_create_by_session(params[:session_id])
    end

    def set_basket_and_product
      @basket = Basket.find_or_create_by_session(params[:session_id])
      @product = Product.find(params[:product_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    end

    def basket_response(basket)
      {
        session_id: basket.session_id,
        items: basket.basket_items.includes(:product).map do |item|
          {
            product_id: item.product.id,
            product_name: item.product.name,
            quantity: item.quantity,
            price: item.price_at_addition,
            line_total: item.line_total
          }
        end,
        total: basket.total_price,
        updated_at: basket.updated_at
      }
    end
  end
end
