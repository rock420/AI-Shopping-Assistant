module Api
  class BasketsController < ApplicationController
    before_action :set_basket, only: [:show, :destroy]
    before_action :set_basket_and_product, only: [:add_item, :update_item, :destroy_item]

    # GET /api/baskets/:session_id
    def show
    end

    # POST /api/baskets/:session_id/items
    def add_item
      quantity = params[:quantity].to_i

      BasketService.add_item(@basket, @product, quantity)

      render :show, status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    rescue InsufficientInventoryError => e
      render json: { 
        error: e.message, 
        available: e.available 
      }, status: :unprocessable_content
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    # PATCH /api/baskets/:session_id/items/:product_id
    def update_item
      new_quantity = params[:quantity].to_i

      BasketService.update_item_quantity(@basket, @product, new_quantity)

      render :show
    rescue InsufficientInventoryError => e
      render json: { 
        error: e.message, 
        available: e.available 
      }, status: :unprocessable_content
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    # DELETE /api/baskets/:session_id/items/:product_id
    # Optional query param: ?quantity=N - if provided, decrements by N; if omitted, removes entire item
    def destroy_item
      quantity = params[:quantity]&.to_i

      BasketService.remove_item(@basket, @product, quantity)

      render :show
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    # DELETE /api/baskets/:session_id
    def destroy
      BasketService.clear_basket(@basket)

      render :show
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
  end
end
