class Api::ProductsController < ApplicationController
  include Pagy::Method

  # GET /api/products
  def index
    per_page = params[:per_page]&.to_i || 20
    per_page = [per_page, 100].min # Cap at 100 items per page
    
    @pagy, @products = pagy(Product.available.order(created_at: :desc), limit: per_page, page: params[:page])
  end
  
  # GET /api/products/:id
  def show
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end
  
  # GET /api/products/search
  def search
    @filters = build_search_filters
    products = ProductSearchService.new.search(@filters)
    
    per_page = params[:per_page]&.to_i || 20
    per_page = [per_page, 100].min
    
    @pagy, @products = pagy(products, limit: per_page, page: params[:page])
  end
  
  private
  
  def build_search_filters
    filters = {}
    
    # Text query
    filters[:query] = params[:query] if params[:query].present?
    
    # Price range
    filters[:min_price] = params[:min_price].to_f if params[:min_price].present?
    filters[:max_price] = params[:max_price].to_f if params[:max_price].present?
    
    # JSONB attributes (color, size, category, etc.)
    filters[:attributes] = {}
    [:color, :size, :category, :subcategory, :material, :brand, :gender].each do |attr|
      filters[:attributes][attr] = params[attr] if params[attr].present?
    end
    
    filters
  end
end
