class Order < ApplicationRecord
  # Constants
  PENDING_ORDER_EXPIRY_MINUTES = 15

  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :session_id, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  # Associations
  has_many :order_items, dependent: :destroy
  has_one :payment

  # Scopes
  scope :expired, -> { where(status: 'pending').where('expires_at < ?', Time.current) }

  # Callbacks
  before_validation :generate_order_number, on: :create
  before_validation :set_expiry_for_pending, on: :create

  # Checks if the order has expired
  #
  # @return [Boolean] true if order is pending and past expiry time
  def expired?
    status == 'pending' && expires_at.present? && expires_at < Time.current
  end

  # Cancels all expired pending orders (will be invoke periodically by some cron job)
  #
  # @return [Integer] Number of orders cancelled
  def self.cancel_expired_orders
    expired_orders = expired.to_a
    expired_orders.each do |order|
      order.update(status: 'cancelled')
    end
    expired_orders.count
  end

  private

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

  # Sets expiry time for pending orders
  def set_expiry_for_pending
    if status == 'pending' && expires_at.nil?
      self.expires_at = PENDING_ORDER_EXPIRY_MINUTES.minutes.from_now
    end
  end
end
