class Api::ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index, :show, :search]
  
  # GET /api/products
  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    per_page = [per_page, 100].min # Cap at 100 items per page
    
    products = Product.available.order(created_at: :desc)
    
    total_count = products.count
    total_pages = (total_count.to_f / per_page).ceil
    
    # paginated results
    paginated_products = products.limit(per_page).offset((page - 1) * per_page)
    
    render json: {
      products: paginated_products.as_json(only: [:id, :name, :description, :price, :inventory_quantity, :product_attributes]),
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end
  
  # GET /api/products/:id
  def show
    product = Product.find(params[:id])
    
    render json: {
      product: product.as_json(only: [:id, :name, :description, :price, :inventory_quantity, :product_attributes])
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end
  
  # GET /api/products/search
  def search
    filters = build_search_filters
    products = ProductSearchService.new.search(filters)
    
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    per_page = [per_page, 100].min
    
    total_count = products.count
    total_pages = (total_count.to_f / per_page).ceil
    
    paginated_products = products.limit(per_page).offset((page - 1) * per_page)
    
    render json: {
      products: paginated_products.as_json(only: [:id, :name, :description, :price, :inventory_quantity, :product_attributes]),
      filters_applied: filters,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
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
