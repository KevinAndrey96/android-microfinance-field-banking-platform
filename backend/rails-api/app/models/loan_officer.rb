class LoanOfficer < ApplicationRecord
  has_many :collection_routes, dependent: :destroy
  has_many :loans, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error
  has_many :penalties, dependent: :restrict_with_error
  has_many :gps_pings, dependent: :destroy
  has_many :cash_reconciliations, dependent: :destroy
  has_many :vehicle_expenses, dependent: :destroy

  validates :document_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, inclusion: { in: %w[collector supervisor admin] }

  scope :active, -> { where(active: true) }

  def short_code
    document_number.to_s.last(4)
  end
end
