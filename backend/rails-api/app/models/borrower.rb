class Borrower < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error
  has_many :co_signers, dependent: :destroy

  validates :document_number, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :status, inclusion: { in: %w[active blocked delinquent] }

  scope :active, -> { where(status: "active") }
  scope :blocked, -> { where(status: "blocked") }
  scope :delinquent, -> { where(status: "delinquent") }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def active_loan
    loans.where(status: %w[active in_arrears]).order(created_at: :desc).first
  end
end
