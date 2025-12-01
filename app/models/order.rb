class Order < ApplicationRecord
  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :session_id, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  # Associations
  has_many :order_items, dependent: :destroy

  # Callbacks
  before_validation :generate_order_number, on: :create
  before_save :validate_inventory

  private

  # Validates that sufficient inventory exists for all order items.
  # Called before_save to prevent orders when inventory is insufficient
  def validate_inventory
    order_items.each do |item|
      product = item.product
      unless product.inventory_quantity >= item.quantity
        errors.add(:base, "Insufficient inventory for #{product.name}. Available: #{product.inventory_quantity}, Requested: #{item.quantity}")
        throw(:abort)
      end
    end
  end

  # Generates a unique, human-readable order number.
  # Format: ORD-YYYYMMDD-XXXXXXXX (e.g., ORD-20250112-A1B2C3D4)
  # - Date prefix for human readability
  # - 8 random alphanumeric characters
  # - Database unique constraint ensures no collisions
  def generate_order_number
    return if order_number.present?
    
    # Though collision probability is negligible, We need to handle collisions while scaling
    date_part = Time.current.strftime('%Y%m%d')
    random_part = SecureRandom.alphanumeric(8).upcase
    self.order_number = "ORD-#{date_part}-#{random_part}"
  end
end
