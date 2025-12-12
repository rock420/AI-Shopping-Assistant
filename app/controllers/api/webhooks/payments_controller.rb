module Api
  module Webhooks
    class PaymentsController < ApplicationController
      # skipping CSRF token validation. 
      # Ideally we would have some signature verifiction or api key verification
      skip_before_action :verify_authenticity_token

      # POST /api/webhooks/payments
      # Handles payment provider webhook notifications
      #
      # Expected payload:
      # {
      #   "event": "payment.succeeded" | "payment.failed",
      #   "payment_id": "pay_xyz123",
      #   "amount": 99.99,
      #   "method": "card",
      #   "metadata": {
      #     "order_number": "ORD-20250112-ABC123",
      #     "conversation_id": "XXXXXXXX"  # optional 
      #    }
      # }
      def create
        payload = params.permit(:event, :payment_id, :amount, :method, metadata: [:order_number, :conversation_id])
        
        order = Order.find_by(order_number: payload[:metadata][:order_number])
        if order.nil?
          return render json: { error: 'Order not found' }, status: :not_found
        end

        case payload[:event]
        when 'payment.succeeded'
          PaymentService.process_success(order, payload[:payment_id], payload[:amount], payload[:method], payload[:metadata])
        when 'payment.failed'
          PaymentService.process_failure(order,  payload[:payment_id], payload[:amount], payload[:method], payload[:metadata])
        else
          return render json: { error: 'Unknown event type' }, status: :bad_request
        end

        render json: { status: 'processed' }, status: :ok
      rescue OrderExpiredError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue InsufficientInventoryError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue StandardError => e
        logger.error "Webhook processing failed: #{e.class} - #{e.message}"
        logger.error e.backtrace.join("\n")
        render json: { error: 'Webhook processing failed' }, status: :internal_server_error
      end

    end
  end
end
