module Api
  module V1
    class BorrowersController < ApplicationController
      def index
        borrowers = Borrower.all
        borrowers = borrowers.where(status: params[:status]) if params[:status].present?
        borrowers = borrowers.where(city: params[:city]) if params[:city].present?

        render json: borrowers
      end

      def show
        borrower = Borrower.includes(:loans, :co_signers).find_by!(document_number: params[:id])
        render json: borrower.as_json(
          include: {
            loans: { only: %i[id loan_number principal_amount total_amount balance_due status installment_frequency] },
            co_signers: { only: %i[id name document_number phone relationship] }
          }
        )
      end

      def create
        borrower = Borrower.create!(borrower_params)
        render json: borrower, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def borrower_params
        params.require(:borrower).permit(
          :document_number, :first_name, :last_name, :phone, :address,
          :neighborhood, :city, :department, :latitude, :longitude,
          :zodiac_sign, :status, :notes
        )
      end
    end
  end
end
