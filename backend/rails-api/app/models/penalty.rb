class Penalty < ApplicationRecord
  belongs_to :loan
  belongs_to :loan_officer

  validates :amount, :reason, :applied_at, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending paid waived] }
end
