class VehicleExpense < ApplicationRecord
  belongs_to :loan_officer

  validates :expense_type, :amount, :recorded_at, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
