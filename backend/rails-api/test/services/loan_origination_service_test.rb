require "test_helper"

class LoanOriginationServiceTest < ActiveSupport::TestCase
  setup do
    @officer = LoanOfficer.create!(
      document_number: "777123456",
      name: "Pedro Inspector",
      role: "collector",
      pin_code: "1234"
    )
    @borrower = Borrower.create!(
      document_number: "666765432",
      first_name: "Lucia",
      last_name: "Morales",
      city: "El Espinal",
      status: "active"
    )
  end

  test "originates loan with 20% interest and 30 daily installments" do
    loan = LoanOriginationService.call(
      borrower: @borrower,
      loan_officer: @officer,
      principal_amount: 1_000_000,
      installment_count: 30,
      frequency: "daily",
      interest_rate_percent: 20.0,
      insurance_amount: 30_000
    )

    assert_equal 1_000_000, loan.principal_amount
    assert_equal 1_230_000, loan.total_amount
    assert_equal 41_000, loan.installment_amount
    assert_equal 30, loan.installments.count
    assert_equal "active", loan.status
    assert_equal 1_230_000, loan.balance_due

    # Verify reconciliation updated
    rec = CashReconciliation.find_by(loan_officer: @officer, reconciliation_date: Date.current)
    assert rec.present?
    assert_equal 1_000_000, rec.total_disbursed
  end

  test "rejects origination for blocked borrower" do
    @borrower.update!(status: "blocked")

    assert_raises(LoanOriginationService::Error) do
      LoanOriginationService.call(
        borrower: @borrower,
        loan_officer: @officer,
        principal_amount: 500_000
      )
    end
  end
end
