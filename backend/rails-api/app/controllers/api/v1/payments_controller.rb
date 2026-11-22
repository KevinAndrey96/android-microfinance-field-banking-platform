module Api
  module V1
    class PaymentsController < ApplicationController
      def index
        payments = Payment.includes(:loan, :loan_officer).order(payment_date: :desc).limit(100)
        render json: payments.as_json(
          include: {
            loan: { only: %i[id loan_number balance_due total_amount status] },
            loan_officer: { only: %i[id name document_number] }
          }
        )
      end

      def create
        loan = Loan.find_by!(loan_number: params[:loan_number])
        officer = LoanOfficer.find_by!(document_number: params[:loan_officer_document])

        payment = PaymentProcessingService.call(
          loan: loan,
          loan_officer: officer,
          amount: params[:amount],
          printed_thermal: params[:printed_thermal].to_s == "true",
          sms_sent: params[:sms_sent].to_s == "true",
          latitude: params[:latitude],
          longitude: params[:longitude]
        )

        render json: payment, status: :created
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      rescue PaymentProcessingService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
