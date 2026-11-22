class PaymentProcessingService
  class Error < StandardError; end

  def self.call(loan:, loan_officer:, amount:, payment_date: Time.current, printed_thermal: false, sms_sent: false, signature_path: nil, latitude: nil, longitude: nil)
    new(
      loan: loan,
      loan_officer: loan_officer,
      amount: amount.to_d,
      payment_date: payment_date,
      printed_thermal: printed_thermal,
      sms_sent: sms_sent,
      signature_path: signature_path,
      latitude: latitude,
      longitude: longitude
    ).execute
  end

  def initialize(loan:, loan_officer:, amount:, payment_date:, printed_thermal:, sms_sent:, signature_path:, latitude:, longitude:)
    @loan = loan
    @loan_officer = loan_officer
    @amount = amount
    @payment_date = payment_date
    @printed_thermal = printed_thermal
    @sms_sent = sms_sent
    @signature_path = signature_path
    @latitude = latitude
    @longitude = longitude
  end

  def execute
    validate_payment!

    Loan.transaction do
      prev_balance = @loan.balance_due
      new_balance = [prev_balance - @amount, 0.0].max
      receipt_num = generate_unique_receipt_number

      payment = Payment.create!(
        receipt_number: receipt_num,
        loan: @loan,
        loan_officer: @loan_officer,
        amount_paid: @amount,
        previous_balance: prev_balance,
        new_balance: new_balance,
        payment_date: @payment_date,
        printed_thermal_receipt: @printed_thermal,
        sms_sent: @sms_sent,
        signature_image_path: @signature_path,
        latitude: @latitude,
        longitude: @longitude
      )

      # Distribute payment into installments
      distribute_installments!(@amount)

      # Update loan balance
      @loan.recalculate_balance!

      # Update cash reconciliation ledger
      reconciliation = CashReconciliation.find_or_create_by!(
        loan_officer: @loan_officer,
        reconciliation_date: Date.current
      )
      reconciliation.increment!(:total_collected, @amount)
      reconciliation.compute_expected_closing!

      payment
    end
  end

  private

  def validate_payment!
    if @amount <= 0
      raise Error, "Payment amount must be greater than zero"
    end

    if @loan.status == "paid_off" || @loan.balance_due <= 0
      raise Error, "Loan is already fully paid off"
    end
  end

  def distribute_installments!(amount_to_distribute)
    remaining = amount_to_distribute
    @loan.installments.pending_or_partial.each do |inst|
      break if remaining <= 0

      needed = inst.amount_due - inst.amount_paid
      if remaining >= needed
        inst.update!(
          amount_paid: inst.amount_due,
          status: "paid",
          paid_at: @payment_date
        )
        remaining -= needed
      else
        inst.update!(
          amount_paid: inst.amount_paid + remaining,
          status: "partial"
        )
        remaining = 0
      end
    end
  end

  def generate_unique_receipt_number
    loop do
      candidate = "REC-#{SecureRandom.random_number(100_000..999_999)}"
      break candidate unless Payment.exists?(receipt_number: candidate)
    end
  end
end
