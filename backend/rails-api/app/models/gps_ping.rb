class GpsPing < ApplicationRecord
  belongs_to :loan_officer

  validates :latitude, :longitude, :recorded_at, presence: true
end
