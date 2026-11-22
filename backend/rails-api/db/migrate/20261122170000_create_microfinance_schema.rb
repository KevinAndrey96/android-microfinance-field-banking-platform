class CreateMicrofinanceSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_officers do |t|
      t.string :document_number, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :role, default: "collector", null: false
      t.string :motorcycle_plate
      t.string :pin_code
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    create_table :borrowers do |t|
      t.string :document_number, null: false, index: { unique: true }
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.string :address
      t.string :neighborhood
      t.string :city, default: "Ibagué", null: false
      t.string :department, default: "Tolima", null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :zodiac_sign
      t.string :status, default: "active", null: false
      t.text :notes

      t.timestamps
    end

    create_table :co_signers do |t|
      t.references :borrower, null: false, foreign_key: true
      t.string :name, null: false
      t.string :document_number, null: false
      t.string :phone
      t.string :relationship
      t.string :address

      t.timestamps
    end

    create_table :collection_routes do |t|
      t.string :name, null: false
      t.string :code, null: false, index: { unique: true }
      t.string :zone, null: false
      t.string :frequency, default: "daily", null: false
      t.references :loan_officer, null: false, foreign_key: true
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    create_table :loans do |t|
      t.string :loan_number, null: false, index: { unique: true }
      t.references :borrower, null: false, foreign_key: true
      t.references :loan_officer, null: false, foreign_key: true
      t.references :collection_route, foreign_key: true
      t.decimal :principal_amount, precision: 12, scale: 2, null: false
      t.decimal :interest_rate_percent, precision: 5, scale: 2, default: 20.0, null: false
      t.decimal :insurance_amount, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :total_amount, precision: 12, scale: 2, null: false
      t.integer :installment_count, default: 30, null: false
      t.string :installment_frequency, default: "daily", null: false
      t.decimal :installment_amount, precision: 12, scale: 2, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :balance_due, precision: 12, scale: 2, null: false
      t.integer :overdue_installments_count, default: 0, null: false
      t.decimal :overdue_amount, precision: 12, scale: 2, default: 0.0, null: false
      t.string :status, default: "active", null: false
      t.datetime :disbursed_at

      t.timestamps
    end

    create_table :installments do |t|
      t.references :loan, null: false, foreign_key: true
      t.integer :installment_number, null: false
      t.date :due_date, null: false
      t.decimal :amount_due, precision: 12, scale: 2, null: false
      t.decimal :amount_paid, precision: 12, scale: 2, default: 0.0, null: false
      t.string :status, default: "pending", null: false
      t.datetime :paid_at

      t.timestamps
    end

    create_table :payments do |t|
      t.string :receipt_number, null: false, index: { unique: true }
      t.references :loan, null: false, foreign_key: true
      t.references :loan_officer, null: false, foreign_key: true
      t.decimal :amount_paid, precision: 12, scale: 2, null: false
      t.decimal :previous_balance, precision: 12, scale: 2, null: false
      t.decimal :new_balance, precision: 12, scale: 2, null: false
      t.datetime :payment_date, null: false
      t.boolean :printed_thermal_receipt, default: false, null: false
      t.boolean :sms_sent, default: false, null: false
      t.string :signature_image_path
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      t.timestamps
    end

    create_table :penalties do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :loan_officer, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :reason, null: false
      t.datetime :applied_at, null: false
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    create_table :gps_pings do |t|
      t.references :loan_officer, null: false, foreign_key: true
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.string :address_resolved
      t.decimal :speed, precision: 6, scale: 2
      t.integer :battery_level
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    create_table :cash_reconciliations do |t|
      t.references :loan_officer, null: false, foreign_key: true
      t.date :reconciliation_date, null: false
      t.decimal :opening_balance, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :total_collected, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :total_disbursed, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :total_expenses, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :salary_advance, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :closing_balance, precision: 12, scale: 2, default: 0.0, null: false
      t.string :status, default: "open", null: false
      t.text :notes

      t.timestamps
    end

    create_table :vehicle_expenses do |t|
      t.references :loan_officer, null: false, foreign_key: true
      t.string :expense_type, default: "fuel", null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :odometer_reading
      t.string :notes
      t.datetime :recorded_at, null: false

      t.timestamps
    end
  end
end
