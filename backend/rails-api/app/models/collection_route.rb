class CollectionRoute < ApplicationRecord
  belongs_to :loan_officer
  has_many :loans, dependent: :nullify

  validates :name, :code, :zone, presence: true
  validates :code, uniqueness: true
  validates :frequency, inclusion: { in: %w[daily weekly biweekly monthly] }

  scope :active, -> { where(active: true) }
end
