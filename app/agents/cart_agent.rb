class CartAgent
  include Singleton
  
  attr_reader :agent

  VALID_UI_ACTIONS = %w[
    show_basket
    show_order_payment
    show_order_confirmation
    show_order_details
  ].freeze

  
  def initialize
    @agent = build_agent
    register_tools
  end
  
  # Run cart agent with streaming
  #
  # @param message [String] User's message
  # @param session_id [String] Current sessionId of the user
  # @param context [Hash] Additional context
  # @yield [Hash] Streams response chunks
  def run_stream(message, session_id, context: {}, &block)
    context_with_session = context.merge(session_id: session_id)

    @agent.run_stream(message, context: context_with_session, &block)
  end
  
  private
  
  def build_agent
    system_prompt = <<~PROMPT
      You are a shopping cart assistant. Your role is to help customers manage their shopping basket and place order.
      Only use the tools provided to help them.
      
      You can:
      - Add products to the basket
      - Remove products from the basket
      - Update quantities
      - View basket contents
      - Calculate totals
      - Clear the basket
      - Place an order
      - Render UI
      
      IMPORTANT:
      - Always use the provided tools to interact with the basket.
      - Be helpful and confirm critical actions like placing order, clearing basket clearly.
      - Before placing order confirm the total amount and quantity.
      - Always provide the current basket total after changes.

      
      UI RENDERING INSTRUCTIONS:
      - Call the render_ui tool as your FINAL action before responding to the user
      - The render_ui tool determines what visual component the user sees
      - Set 'action' to the appropriate UI view:
        * 'show_basket' - MANDATORY after adding/removing any item or for viewing basket to update UI. NEVER SKIP.
        * 'show_order_payment' - MANDATORY after creating an order to show payment page. NEVER SKIP.
        * 'show_order_confirmation' - for showing order confirmation after payment
        * 'show_order_details' - for displaying details of an existing order
      - Set 'data_source' to the exact name of the tool that generated the data to display:
        * Use 'view_basket' when showing basket contents
        * Use 'create_order' when showing payment page
        * Use 'view_order' when showing order details or confirmation page
      - Example workflows:
        * Add item: add_item_to_basket → render_ui(action: "show_basket", data_source: "add_item_to_basket") → respond
        * Place order: create_order → render_ui(action: "show_order_payment", data_source: "create_order") → respond
        * View order: view_order → render_ui(action: "show_order_details", data_source: "view_order") → respond
      
    PROMPT
    
    Agent.new(system_prompt: system_prompt, tools: cart_tools, name: "cart_management_assistant")
  end
  
  def cart_tools
    [
      {
        type: "function",
        function: {
          name: "view_basket",
          description: "View the current contents of the shopping basket",
          parameters: {
            type: "object",
            properties: {},
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "add_item_to_basket",
          description: "Add a product to the shopping basket",
          parameters: {
            type: "object",
            properties: {
              product_id: {
                type: "integer",
                description: "The ID of the product to add"
              },
              quantity: {
                type: "integer",
                description: "Quantity to add (default: 1)",
                default: 1
              }
            },
            required: ["product_id"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "remove_item_from_basket",
          description: "Remove a product from the shopping basket",
          parameters: {
            type: "object",
            properties: {
              product_id: {
                type: "integer",
                description: "The ID of the product to remove"
              },
              quantity: {
                type: "integer",
                description: "Quantity to remove (omit to remove all)",
                default: nil
              }
            },
            required: ["product_id"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "update_basket_item",
          description: "Update the quantity of a product in the basket",
          parameters: {
            type: "object",
            properties: {
              product_id: {
                type: "integer",
                description: "The ID of the product to update"
              },
              quantity: {
                type: "integer",
                description: "New quantity"
              }
            },
            required: ["product_id", "quantity"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "clear_basket",
          description: "Remove all items from the basket",
          parameters: {
            type: "object",
            properties: {},
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "get_basket_summary",
          description: "Get a summary of the basket (item count, total price)",
          parameters: {
            type: "object",
            properties: {},
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "create_order",
          description: "Place a pending order from the current basket. User needs to fullfil payment to confirm.",
          parameters: {
            type: "object",
            properties: {},
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "view_order",
          description: "View details of an existing order by order number",
          parameters: {
            type: "object",
            properties: {
              order_number: {
                type: "string",
                description: "The order number to retrieve"
              }
            },
            required: ["order_number"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "render_ui",
          description: "Render a UI component to display data to the user. This determines what visual interface the user sees. CRITICAL: Always call this after create_order to show the payment page.",
          parameters: {
            type: "object",
            properties: {
              action: {
                type: "string",
                description: "The UI component to render. Choose based on the data you want to display.",
                enum: ["show_basket", "show_order_payment", "show_order_confirmation", "show_order_details"]
              },
              data_source: {
                type: "string",
                description: "The exact name of the tool whose result data should be displayed in the UI. Must match a previously called tool name.",
                enum: ["view_basket", "add_item_to_basket", "remove_item_from_basket", "update_basket_item", "clear_basket", "create_order", "view_order"]
              }
            },
            required: ["action", "data_source"]
          }
        }
      }
    ]
  end
  
  def register_tools
    @agent.register_tool("view_basket") { |args, context| handle_view_basket(args, context) }
    @agent.register_tool("add_item_to_basket") { |args, context| handle_add_item_to_basket(args, context) }
    @agent.register_tool("remove_item_from_basket") { |args, context| remove_item_from_basket(args, context) }
    @agent.register_tool("update_basket_item") { |args, context| handle_update_basket_item(args, context) }
    @agent.register_tool("clear_basket") { |args, context| handle_clear_basket(args, context) }
    @agent.register_tool("get_basket_summary") { |args, context| handle_get_basket_summary(context) }
    @agent.register_tool("create_order") { |args, context| handle_create_order(context) }
    @agent.register_tool("view_order") { |args| handle_view_order(args) }
    @agent.register_tool("render_ui") { |args, context| handle_render_ui(args, context) }
  end

  def handle_view_basket(args, context)
    basket = get_basket(context[:session_id])
    render_basket(basket)
  end

  def handle_add_item_to_basket(args, context)
    basket = get_basket(context[:session_id])
    product = get_product(args["product_id"])
    quantity = args["quantity"] || 1
    
    BasketService.add_item(basket, product, quantity)
    render_basket(basket.reload, "Item added successfully - UI update require")
  rescue ActiveRecord::RecordNotFound
    { success: false, error: "Product not found", product_id: args["product_id"] }
  rescue InsufficientInventoryError => e
    { success: false, error: e.message, available: e.available }
  rescue ArgumentError => e
    { success: false, error: e.message }
  end

  def remove_item_from_basket(args, context)
    basket = get_basket(context[:session_id])
    product = get_product(args["product_id"])
    quantity = args["quantity"]
    
    BasketService.remove_item(basket, product, quantity)
    render_basket(basket.reload, "Item removed successfully - UI update require")
  rescue ActiveRecord::RecordNotFound
    { success: false, error: "Product not found", product_id: args["product_id"] }
  rescue ArgumentError => e
    { success: false, error: e.message }
  end

  def handle_update_basket_item(args, context)
    basket = get_basket(context[:session_id])
    product = get_product(args["product_id"])
    new_quantity = args["quantity"]
    
    BasketService.update_item_quantity(basket, product, new_quantity)
    
    render_basket(basket.reload, "Item updated successfully")
  rescue ActiveRecord::RecordNotFound
    { success: false, error: "Product not found", product_id: args["product_id"] }
  rescue InsufficientInventoryError => e
    { success: false, error: e.message, available: e.available }
  rescue ArgumentError => e
    { success: false, error: e.message }
  end

  def handle_clear_basket(args, context)
    basket = get_basket(context[:session_id])
    BasketService.clear_basket(basket)
    render_basket(basket.reload, "Basket cleared - UI update require")
  end

  def handle_get_basket_summary(context)
    basket = get_basket(context[:session_id])
    {
      total_item_count: basket.basket_items.sum(:quantity),
      unique_product_count: basket.basket_items.count,
      total: basket.total_price.to_f
    }
  end

  def handle_render_ui(args, context)
    action = args["action"]
    data_source = args["data_source"]
    unless VALID_UI_ACTIONS.include?(action)
      return { success: false, error: "Invalid UI action" }
    end
    
    {
      ui_action: action,
      data_source: data_source,
      success: true
    }
  end

  def handle_create_order(context)
    basket = get_basket(context[:session_id])
    
    if basket.basket_items.empty?
      return { success: false, error: "Cannot create order from empty basket" }
    end
    
    order = OrderService.create_from_basket(basket)
    render_order(order, "Order created successfully - Show payment page")
  rescue InsufficientInventoryError => e
    { success: false, error: e.message }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  rescue ArgumentError => e
    { success: false, error: e.message }
  end

  def handle_view_order(args)
    order_number = args["order_number"]
    
    if order_number.blank?
      return { success: false, error: "Order number is required" }
    end
    
    order = Order.find_by(order_number: order_number)
    
    if order.nil?
      return { success: false, error: "Order not found", order_number: order_number }
    end
    
    render_order(order)
  end

  def get_basket(session_id)
    raise ArgumentError, "Session ID is required" if session_id.blank?
    Basket.find_or_create_by_session(session_id)
  end

  def get_product(product_id)
    raise ArgumentError, "Product ID is required" if product_id.blank?
    Product.find(product_id)
  end

  def render_basket(basket, message = "")
    result = JSON.parse(
      ApplicationController.render(
        template: 'api/baskets/show',
        formats: [:json],
        assigns: { basket: basket }
      )
    )
    result.merge!('message' => message) if message.present?
    result
  end

  def render_order(order, message = nil)
    result = JSON.parse(
      ApplicationController.render(
        template: 'api/orders/show',
        formats: [:json],
        assigns: { order: order }
      )
    )
    result.merge!('message' => message) if message.present?
    result
  end
end
