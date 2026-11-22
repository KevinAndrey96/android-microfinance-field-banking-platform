require "test_helper"

class PaymentProcessingServiceTest < ActiveSupport::TestCase
  setup do
    @officer = LoanOfficer.create!(
      document_number: "555123456",
      name: "Martin Cobrador",
      role: "collector",
      pin_code: "1234"
    )
    @borrower = Borrower.create!(
      document_number: "444765432",
      first_name: "Rosa",
      last_name: "Mendoza",
      city: "Melgar",
      status: "active"
    )
    @loan = LoanOriginationService.call(
      borrower: @borrower,
      loan_officer: @officer,
      principal_amount: 300_000,
      installment_count: 30,
      frequency: "daily",
      interest_rate_percent: 20.0
    )
  end

  test "processes field payment and applies across installments" do
    installment_val = @loan.installment_amount
    payment = PaymentProcessingService.call(
      loan: @loan,
      loan_officer: @officer,
      amount: installment_val * 2,
      printed_thermal: true,
      sms_sent: true,
      latitude: 4.205,
      longitude: -74.643
    )

    assert payment.persisted?
    assert_match(/^REC-/, payment.receipt_number)
    assert payment.printed_thermal_receipt
    assert payment.sms_sent

    @loan.reload
    assert_equal 360_000 - (installment_val * 2), @loan.balance_due
    assert_equal 2, @loan.installments.where(status: "paid").count

    # Check cash reconciliation ledger
    rec = CashReconciliation.find_by(loan_officer: @officer, reconciliation_date: Date.current)
    assert rec.present?
    assert_equal installment_val * 2, rec.total_collected
  end
end
