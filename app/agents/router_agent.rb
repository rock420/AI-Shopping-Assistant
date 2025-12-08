class RouterAgent
  include Singleton
  
  def initialize
    @classifier = build_classifier
  end
  
  def cart_agent
    CartAgent.instance
  end
  
  def product_search_agent
    ProductSearchAgent.instance
  end
  
  def chitchat_agent
    ChitchatAgent.instance
  end
  
  # Route a message with streaming
  #
  # @param message [String] User's message
  # @param session_id [String] User's session ID
  # @param context [Hash] Conversation context
  # @yield [Hash] Streams response chunks with agent type
  def route_stream(message, session_id, context: {}, &block)
    agent_type = classify_message(message, context)
    
    yield({
      type: "agent_selected",
      agent_type: agent_type,
      done: false
    })
    
    route_to_agent_stream(agent_type, message, session_id, context, &block)
  end
  
  private
  
  def route_to_agent_stream(agent_type, message, session_id, context, &block)    
    case agent_type
    when :cart
      cart_agent.run_stream(message, session_id, context: context, &block)
    when :product_search
      product_search_agent.run_stream(message, context: context, &block)
    when :chitchat
      chitchat_agent.run_stream(message, context: context, &block)
    else
      chitchat_agent.run_stream(message, context: context, &block)
    end
  end
  
  def build_classifier
    system_prompt = <<~PROMPT
      You are a message classifier for an e-commerce shopping assistant.
      Your job is to analyze the last few messages of a conversation and correctly determine which specialized agent should handle them.
      Emphasize on the latest user's message.
      
      Available agents:
      1. cart_management - Handles shopping cart operations (add, remove, view basket, update quantities, checkout, order)
      2. product_search - Handles product discovery (search, filter, view details, recommendations)
      3. general_conversation - Handles greetings, policies, support questions, general chat
      
      Classification rules:
      - If the message is about adding, removing, viewing, or managing items in the cart/basket/order → cart_management
      - If the message is about finding, searching, browsing, or viewing products → product_search
      - If the message is about policies, shipping, returns, support, or general questions → general_conversation
      - If the message is a greeting or casual conversation → general_conversation
      
      Respond with **ONLY** the agent name: cart_management, product_search, or general_conversation
    PROMPT
    
    Agent.new(system_prompt: system_prompt, tools: [])
  end
  
  def classify_message(message, context)
    # We can use some regex matching or small ML based classifier model first
    llm_classify(message, context)
  rescue StandardError => e
    Rails.logger.error "RouterAgent classification error: #{e.message}"
    :chitchat
  end
  
  def llm_classify(message, context)
    context_str = build_context_string(context)
    
    prompt = <<~PROMPT
      CONTEXT:
      #{context_str}
      
      User message: "#{message}"
      
      Which agent should handle this? Respond with ONLY: cart_management, product_search, or general_conversation
    PROMPT
    
    result = @classifier.run(prompt)
    parse_classification_result(result[:content])
  end
  
  def build_context_string(context)
    return "" unless context[:messages]&.any?
    
    recent = context[:messages].last(5)
    "Recent conversation:\n" + recent.map { |m| "#{m['role']}: #{m['content']}" }.join("\n")
  end

  # Parse the classification result from LLM response
  #
  # @param content [String] LLM response content
  # @return [Symbol] Agent type (:cart, :product_search, or :chitchat)
  def parse_classification_result(content)
    return :chitchat if content.blank?
    
    # Normalize the content: downcase and strip whitespace
    normalized = content.strip.downcase
    
    # Extract the agent name from the response
    case normalized
    when /cart_management|cart/
      :cart
    when /product_search|product/
      :product_search
    when /general_conversation|general|chitchat/
      :chitchat
    else
      # Default to chitchat if unclear
      Rails.logger.warn "RouterAgent: Unclear classification result: '#{content}', defaulting to chitchat"
      :chitchat
    end
  end
  
end
