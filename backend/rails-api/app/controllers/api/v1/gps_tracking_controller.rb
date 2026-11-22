module Api
  module V1
    class GpsTrackingController < ApplicationController
      def index
        pings = GpsPing.includes(:loan_officer).order(recorded_at: :desc).limit(100)
        pings = pings.where(loan_officer_id: params[:loan_officer_id]) if params[:loan_officer_id].present?

        render json: pings.as_json(
          include: { loan_officer: { only: %i[id name document_number motorcycle_plate] } }
        )
      end

      def create
        officer = LoanOfficer.find_by!(document_number: params[:loan_officer_document])
        ping = officer.gps_pings.create!(
          latitude: params[:latitude],
          longitude: params[:longitude],
          address_resolved: params[:address],
          speed: params[:speed],
          battery_level: params[:battery_level],
          recorded_at: params[:recorded_at] ? Time.zone.parse(params[:recorded_at]) : Time.current
        )

        render json: ping, status: :created
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      end
    end
  end
end
