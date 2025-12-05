class Payment < ApplicationRecord
  # Associations
  belongs_to :order

  # Validations
  validates :payment_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[succeeded failed] }
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :succeeded, -> { where(status: 'succeeded') }
  scope :failed, -> { where(status: 'failed') }
end
