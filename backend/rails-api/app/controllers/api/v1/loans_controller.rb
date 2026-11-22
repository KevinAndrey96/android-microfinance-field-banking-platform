module Api
  module V1
    class LoansController < ApplicationController
      def index
        loans = Loan.includes(:borrower, :loan_officer)
        loans = loans.where(status: params[:status]) if params[:status].present?
        loans = loans.where(installment_frequency: params[:frequency]) if params[:frequency].present?

        render json: loans.as_json(
          include: {
            borrower: { only: %i[id document_number first_name last_name phone address city neighborhood status] },
            loan_officer: { only: %i[id name document_number motorcycle_plate] }
          }
        )
      end

      def show
        loan = Loan.includes(:borrower, :loan_officer, :installments, :payments).find_by!(loan_number: params[:id])
        render json: loan.as_json(
          include: {
            borrower: { only: %i[id document_number first_name last_name phone address city neighborhood status zodiac_sign] },
            loan_officer: { only: %i[id name document_number motorcycle_plate] },
            installments: { only: %i[id installment_number due_date amount_due amount_paid status paid_at] },
            payments: { only: %i[id receipt_number amount_paid previous_balance new_balance payment_date printed_thermal_receipt sms_sent] }
          }
        )
      end

      def create
        borrower = Borrower.find_by!(document_number: params[:borrower_document])
        officer = LoanOfficer.find_by!(document_number: params[:loan_officer_document])

        loan = LoanOriginationService.call(
          borrower: borrower,
          loan_officer: officer,
          principal_amount: params[:principal_amount],
          installment_count: params[:installment_count] || 30,
          frequency: params[:frequency] || "daily",
          interest_rate_percent: params[:interest_rate_percent] || 20.0,
          insurance_amount: params[:insurance_amount] || 0.0,
          start_date: params[:start_date] ? Date.parse(params[:start_date]) : Date.current
        )

        render json: loan, status: :created
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      rescue LoanOriginationService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
