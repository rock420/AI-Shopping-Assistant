require 'pagy'

class ProductSearchAgent
  include Singleton
  include Pagy::Backend
    
  attr_reader :agent

  VALID_UI_ACTIONS = %w[
    show_product_list
    show_product_details  
  ].freeze
  
  def initialize
    @agent = build_agent
    register_tools
  end
  
  # Run product search agent with streaming
  #
  # @param message [String] User's message
  # @param context [Hash] Conversation context
  # @yield [Hash] Streams response chunks
  def run_stream(message, context: {}, &block)
    @agent.run_stream(message, context: context, &block)
  end
  
  private
  
  def build_agent
    system_prompt = <<~PROMPT
      You are a product search assistant for an e-commerce store. Your role is to help customers find products efficiently.
      
      You can:
      - Search for products by keywords
      - Filter products by attributes (color, size, category, etc.)
      - Filter by price range
      - View detailed product information
      - Suggest related or similar products
      - Answer questions about product availability and specifications
      - Render UI to show products, product details, and related products
      
      Be helpful and proactive:
      - Ask clarifying questions if the search is too broad
      - Suggest filters to narrow down results
      - Highlight key product features
      - Mention if products are in stock
      - Suggest adding products to cart when appropriate
      - Maintain a friendly and helpful tone
      - When showing products, present them in a clear, organized way

      UI RENDERING INSTRUCTIONS:
      - ALWAYS call the render_ui tool as your FINAL action before responding to the user
      - The render_ui tool determines what visual component the user sees
      - Set 'action' to the appropriate UI view:
        * 'show_product_list' - for search results with multiple products
        * 'show_product_details' - for detailed view of a single product
      - Set 'data_source' to the exact name of the tool that generated the data to display:
        * Use 'search_products' when showing search results
        * Use 'get_product_details' when showing a single product's details
      - Example workflow: search_products → render_ui(action: "show_product_list", data_source: "search_products") → respond

    PROMPT
    
    Agent.new(system_prompt: system_prompt, tools: product_search_tools, name: "product_search_assistant")
  end
  
  def product_search_tools
    [
      {
        type: "function",
        function: {
          name: "search_products",
          description: "Search for products by query and optional filters",
          parameters: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "Search query (product name, description, keywords)"
              },
              attributes: {
                type: "object",
                description: "JSONB attribute filters to narrow down search (e.g., {color: 'red', size: 'medium'})"
              },
              min_price: {
                type: "number",
                description: "Minimum price filter"
              },
              max_price: {
                type: "number",
                description: "Maximum price filter"
              },
              category: {
                type: "string",
                description: "Category filter"
              },
              limit: {
                type: "integer",
                description: "Maximum number of results per page (default: 20, max: 100)",
                default: 20
              },
              page: {
                type: "integer",
                description: "Page number for pagination (default: 1)",
                default: 1
              }
            },
            required: []
          }
        }
      },
      {
        type: "function",
        function: {
          name: "get_product_details",
          description: "Get detailed information about a specific product",
          parameters: {
            type: "object",
            properties: {
              product_id: {
                type: "integer",
                description: "The ID of the product"
              }
            },
            required: ["product_id"]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "render_ui",
          description: "Render a UI component to display data to the user. MUST be called as the FINAL tool before your text response. This determines what visual interface the user sees.",
          parameters: {
            type: "object",
            properties: {
              action: {
                type: "string",
                description: "The UI component to render. Choose based on the data you want to display.",
                enum: ["show_product_list", "show_product_details"]
              },
              data_source: {
                type: "string",
                description: "The exact name of the tool whose result data should be displayed in the UI. Must match a previously called tool name (e.g., 'search_products' or 'get_product_details').",
                enum: ["search_products", "get_product_details"]
              }
            },
            required: ["action", "data_source"]
          }
        }
      }
    ]
  end
  
  def register_tools
    @agent.register_tool("search_products") { |args| handle_search_products(args) }
    @agent.register_tool("get_product_details") { |args| handle_get_product_details(args) }
    @agent.register_tool("render_ui") { |args, context| handle_render_ui(args, context) }
  end

  def handle_search_products(args)
    filters = build_filters(args)
    limit = args["limit"] || 20
    limit = [limit, 100].min # Cap at 100
    page = args["page"] || 1
    
    products = ProductSearchService.new.search(filters)
    
    if products.blank?
      { products: [], count: 0, message: "No products found for the specified filters" }
    else
      pagy, paginated_products = pagy(products, offset: limit, page: page)
      render_products(paginated_products, filters, pagy)
    end
  rescue StandardError => e
    Rails.logger.error "ProductSearchAgent search_products error: #{e.message}"
    { products: [], count: 0, error: e.message }
  end

  def handle_get_product_details(args)
    product = Product.find(args["product_id"])
    render_product(product)
  rescue ActiveRecord::RecordNotFound
    { success: false, error: "Product not found", product_id: args["product_id"] }
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

  def build_filters(args)
    filters = {}
    filters[:query] = args["query"] if args["query"].present?
    filters[:min_price] = args["min_price"] if args["min_price"].present?
    filters[:max_price] = args["max_price"] if args["max_price"].present?
    filters[:attributes] = args["attributes"] if args["attributes"].present?
    filters
  end

  def render_product(product)
    JSON.parse(
      ApplicationController.render(
        template: 'api/products/show',
        formats: [:json],
        assigns: { product: product }
      )
    )
  end

  def render_products(products, filters, pagy)
    JSON.parse(
      ApplicationController.render(
        template: 'api/products/search',
        formats: [:json],
        assigns: { products: products, filters: filters, pagy: pagy }
      )
    )
  end
end
