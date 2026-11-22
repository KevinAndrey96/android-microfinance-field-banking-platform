class CashReconciliation < ApplicationRecord
  belongs_to :loan_officer

  validates :reconciliation_date, presence: true
  validates :status, inclusion: { in: %w[open submitted reconciled discrepancy] }

  def compute_expected_closing!
    # Expected closing cash = Opening base + Collections - Disbursements - Expenses - Salary advances
    expected = opening_balance.to_f + total_collected.to_f - total_disbursed.to_f - total_expenses.to_f - salary_advance.to_f
    self.closing_balance = expected
    save!
  end
end
