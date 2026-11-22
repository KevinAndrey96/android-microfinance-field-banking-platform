class Payment < ApplicationRecord
  belongs_to :loan
  belongs_to :loan_officer

  validates :receipt_number, presence: true, uniqueness: true
  validates :amount_paid, :previous_balance, :new_balance, :payment_date, presence: true
  validates :amount_paid, numericality: { greater_than: 0 }

  after_create :apply_to_loan!

  private

  def apply_to_loan!
    loan.recalculate_balance!
  end
end
