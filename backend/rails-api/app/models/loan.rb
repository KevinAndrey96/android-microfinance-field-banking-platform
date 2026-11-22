class Loan < ApplicationRecord
  belongs_to :borrower
  belongs_to :loan_officer
  belongs_to :collection_route, optional: true

  has_many :installments, -> { order(:installment_number) }, dependent: :destroy
  has_many :payments, -> { order(payment_date: :desc) }, dependent: :restrict_with_error
  has_many :penalties, dependent: :destroy

  validates :loan_number, presence: true, uniqueness: true
  validates :principal_amount, :total_amount, :installment_amount, :balance_due, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :installment_count, presence: true, numericality: { greater_than: 0 }
  validates :installment_frequency, inclusion: { in: %w[daily weekly biweekly monthly] }
  validates :status, inclusion: { in: %w[active in_arrears paid_off written_off] }

  scope :active, -> { where(status: %w[active in_arrears]) }
  scope :in_arrears, -> { where(status: "in_arrears") }
  scope :paid_off, -> { where(status: "paid_off") }

  def active?
    %w[active in_arrears].include?(status)
  end

  def in_arrears?
    status == "in_arrears"
  end

  def paid_off?
    status == "paid_off"
  end

  def recalculate_balance!
    paid_sum = payments.sum(:amount_paid)
    new_balance = [total_amount - paid_sum, 0.0].max
    self.balance_due = new_balance

    # Calculate remaining installments
    if installment_amount > 0
      remaining_count = (new_balance / installment_amount).ceil
    else
      remaining_count = 0
    end

    if new_balance <= 0
      self.status = "paid_off"
      self.overdue_installments_count = 0
      self.overdue_amount = 0.0
    elsif overdue_installments_count > 0
      self.status = "in_arrears"
    else
      self.status = "active"
    end

    save!
  end

  def remaining_installments_count
    return 0 if installment_amount.to_f <= 0
    (balance_due.to_f / installment_amount.to_f).ceil
  end
end
