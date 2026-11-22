class LoanOriginationService
  class Error < StandardError; end

  def self.call(borrower:, loan_officer:, principal_amount:, installment_count: 30, frequency: "daily", interest_rate_percent: 20.0, insurance_amount: 0.0, start_date: Date.current, collection_route: nil)
    new(
      borrower: borrower,
      loan_officer: loan_officer,
      principal_amount: principal_amount.to_d,
      installment_count: installment_count.to_i,
      frequency: frequency,
      interest_rate_percent: interest_rate_percent.to_d,
      insurance_amount: insurance_amount.to_d,
      start_date: start_date,
      collection_route: collection_route
    ).execute
  end

  def initialize(borrower:, loan_officer:, principal_amount:, installment_count:, frequency:, interest_rate_percent:, insurance_amount:, start_date:, collection_route:)
    @borrower = borrower
    @loan_officer = loan_officer
    @principal_amount = principal_amount
    @installment_count = [installment_count, 1].max
    @frequency = frequency
    @interest_rate_percent = interest_rate_percent
    @insurance_amount = insurance_amount
    @start_date = start_date
    @collection_route = collection_route
  end

  def execute
    validate_eligibility!

    interest_amount = (@principal_amount * (@interest_rate_percent / 100.0)).round(2)
    total_amount = (@principal_amount + interest_amount + @insurance_amount).round(2)
    installment_amount = (total_amount / @installment_count).round(2)

    # Compute duration days
    days_per_installment = case @frequency
                           when "weekly" then 7
                           when "biweekly" then 14
                           when "monthly" then 30
                           else 1 # daily
                           end

    end_date = @start_date + (@installment_count * days_per_installment).days
    pin_number = generate_unique_loan_pin

    Loan.transaction do
      loan = Loan.create!(
        loan_number: pin_number,
        borrower: @borrower,
        loan_officer: @loan_officer,
        collection_route: @collection_route,
        principal_amount: @principal_amount,
        interest_rate_percent: @interest_rate_percent,
        insurance_amount: @insurance_amount,
        total_amount: total_amount,
        installment_count: @installment_count,
        installment_frequency: @frequency,
        installment_amount: installment_amount,
        start_date: @start_date,
        end_date: end_date,
        balance_due: total_amount,
        status: "active",
        disbursed_at: Time.current
      )

      # Generate installment schedule
      current_due_date = @start_date
      @installment_count.times do |index|
        current_due_date += days_per_installment.days
        # Skip Sundays if daily route
        current_due_date += 1.day if @frequency == "daily" && current_due_date.sunday?

        loan.installments.create!(
          installment_number: index + 1,
          due_date: current_due_date,
          amount_due: installment_amount,
          amount_paid: 0.0,
          status: "pending"
        )
      end

      # Update daily cash reconciliation
      reconciliation = CashReconciliation.find_or_create_by!(
        loan_officer: @loan_officer,
        reconciliation_date: Date.current
      )
      reconciliation.increment!(:total_disbursed, @principal_amount)
      reconciliation.compute_expected_closing!

      loan
    end
  end

  private

  def validate_eligibility!
    if @borrower.status == "blocked"
      raise Error, "Borrower is blocked from credit origination due to risk policy"
    end

    if @principal_amount <= 0
      raise Error, "Principal amount must be greater than zero"
    end
  end

  def generate_unique_loan_pin
    loop do
      candidate = "PIN-#{SecureRandom.random_number(100_000..999_999)}"
      break candidate unless Loan.exists?(loan_number: candidate)
    end
  end
end
