class Product < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :inventory_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Associations
  has_many :basket_items, dependent: :restrict_with_error
  has_many :order_items, dependent: :restrict_with_error

  # Scopes
  scope :available, -> { where('inventory_quantity > 0') }

  # Instance methods
  def available?
    inventory_quantity > 0
  end

  # Atomically decrements inventory using a single SQL UPDATE with WHERE clause.
  # If insufficient inventory, raises an error.
  #
  # @param quantity [Integer] Amount to decrement
  # @raise [ActiveRecord::RecordInvalid] if insufficient inventory
  # @return [void]
  def decrement_inventory!(quantity)
    rows_updated = self.class.where(id: id)
                       .where('inventory_quantity >= ?', quantity)
                       .update_all(['inventory_quantity = inventory_quantity - ?', quantity])
    
    if rows_updated == 0
      reload
      raise ActiveRecord::RecordInvalid, "Insufficient inventory. Available: #{inventory_quantity}, Requested: #{quantity}"
    end
    
    reload
  end

  # Atomically increments inventory using a single SQL UPDATE.
  #
  # @param quantity [Integer] Amount to increment
  # @return [void]
  def increment_inventory!(quantity)
    self.class.where(id: id)
        .update_all(['inventory_quantity = inventory_quantity + ?', quantity])
    reload
  end
end
