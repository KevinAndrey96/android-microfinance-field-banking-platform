module Api
  module V1
    class CashReconciliationsController < ApplicationController
      def index
        reconciliations = CashReconciliation.includes(:loan_officer).order(reconciliation_date: :desc).limit(60)
        render json: reconciliations.as_json(
          include: { loan_officer: { only: %i[id name document_number motorcycle_plate] } }
        )
      end

      def today
        officer = LoanOfficer.find_by!(document_number: params[:loan_officer_document])
        reconciliation = CashReconciliation.find_or_create_by!(
          loan_officer: officer,
          reconciliation_date: Date.current
        )
        reconciliation.compute_expected_closing!

        render json: reconciliation.as_json(
          include: { loan_officer: { only: %i[id name document_number motorcycle_plate] } }
        )
      end
    end
  end
end
