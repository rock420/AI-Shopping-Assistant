module Api
  class OrdersController < ApplicationController
    # POST /api/orders
    # Creates a pending order from the user's basket and initiate payment flow
    #
    # Request body:
    # {
    #   "session_id": "abc123"
    # }
    #
    #
    # Error responses:
    # - 400 Bad Request: Missing session_id
    # - 404 Not Found: Basket not found or empty
    # - 422 Unprocessable Entity: Insufficient inventory or validation errors
    def create
      session_id = params[:session_id]

      if session_id.blank?
        return render json: { error: 'session_id is required' }, status: :bad_request
      end

      basket = Basket.find_by(session_id: session_id)

      if basket.nil?
        return render json: { error: 'Basket not found' }, status: :not_found
      end

      if basket.basket_items.empty?
        return render json: { error: 'Cannot create order from empty basket' }, status: :not_found
      end

      @order = OrderService.create_from_basket(basket)

      # Ideally, we should also generate a secure payment url using any thrid party payment service and sent that
      # for the scope of the assignment, we are omitting that 

      render :create, status: :created
    rescue InsufficientInventoryError => e
      render json: { error: e.message }, status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_content
    rescue StandardError => e
      logger.error "Order creation failed: #{e.class} - #{e.message}"
      logger.error e.backtrace.join("\n")
      render json: { error: 'An unexpected error occurred while creating the order' }, status: :internal_server_error
    end

    # GET /api/orders/:order_number
    # Retrieves order details by order number
    def show
      @order = Order.find_by(order_number: params[:order_number])

      if @order.nil?
        logger.error "Order: #{params[:order_number]} not found"
        return render json: { error: 'Order not found' }, status: :not_found
      end
    end
  end
end
