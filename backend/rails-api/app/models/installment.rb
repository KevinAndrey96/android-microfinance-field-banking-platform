class Installment < ApplicationRecord
  belongs_to :loan

  validates :installment_number, :due_date, :amount_due, presence: true
  validates :status, inclusion: { in: %w[pending paid partial overdue] }

  scope :pending_or_partial, -> { where(status: %w[pending partial overdue]) }
end
