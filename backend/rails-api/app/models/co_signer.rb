class CoSigner < ApplicationRecord
  belongs_to :borrower

  validates :name, :document_number, presence: true
end
