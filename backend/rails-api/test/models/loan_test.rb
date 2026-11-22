require "test_helper"

class LoanTest < ActiveSupport::TestCase
  setup do
    @officer = LoanOfficer.create!(
      document_number: "999123456",
      name: "Juan Test",
      role: "collector",
      pin_code: "1234"
    )
    @borrower = Borrower.create!(
      document_number: "888765432",
      first_name: "Ana",
      last_name: "Perez",
      city: "Ibagué",
      status: "active"
    )
  end

  test "creates loan and calculates balance accurately" do
    loan = Loan.create!(
      loan_number: "PIN-TEST-01",
      borrower: @borrower,
      loan_officer: @officer,
      principal_amount: 500_000,
      total_amount: 600_000,
      installment_count: 30,
      installment_amount: 20_000,
      start_date: Date.current,
      end_date: 30.days.from_now.to_date,
      balance_due: 600_000,
      status: "active"
    )

    assert_equal 600_000, loan.balance_due
    assert_equal 30, loan.remaining_installments_count
    assert loan.active?
  end

  test "recalculates balance after payments" do
    loan = Loan.create!(
      loan_number: "PIN-TEST-02",
      borrower: @borrower,
      loan_officer: @officer,
      principal_amount: 500_000,
      total_amount: 600_000,
      installment_count: 30,
      installment_amount: 20_000,
      start_date: Date.current,
      end_date: 30.days.from_now.to_date,
      balance_due: 600_000,
      status: "active"
    )

    Payment.create!(
      receipt_number: "REC-TEST-01",
      loan: loan,
      loan_officer: @officer,
      amount_paid: 200_000,
      previous_balance: 600_000,
      new_balance: 400_000,
      payment_date: Time.current
    )

    loan.reload
    assert_equal 400_000, loan.balance_due
    assert_equal 20, loan.remaining_installments_count
    assert_equal "active", loan.status
  end
end
