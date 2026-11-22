# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_22_170000) do
  create_table "borrowers", force: :cascade do |t|
    t.string "document_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "address"
    t.string "neighborhood"
    t.string "city", default: "Ibagué", null: false
    t.string "department", default: "Tolima", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "zodiac_sign"
    t.string "status", default: "active", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_number"], name: "index_borrowers_on_document_number", unique: true
  end

  create_table "cash_reconciliations", force: :cascade do |t|
    t.integer "loan_officer_id", null: false
    t.date "reconciliation_date", null: false
    t.decimal "opening_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_collected", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_disbursed", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_expenses", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "salary_advance", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "closing_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.string "status", default: "open", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_officer_id"], name: "index_cash_reconciliations_on_loan_officer_id"
  end

  create_table "co_signers", force: :cascade do |t|
    t.integer "borrower_id", null: false
    t.string "name", null: false
    t.string "document_number", null: false
    t.string "phone"
    t.string "relationship"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["borrower_id"], name: "index_co_signers_on_borrower_id"
  end

  create_table "collection_routes", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "zone", null: false
    t.string "frequency", default: "daily", null: false
    t.integer "loan_officer_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_collection_routes_on_code", unique: true
    t.index ["loan_officer_id"], name: "index_collection_routes_on_loan_officer_id"
  end

  create_table "gps_pings", force: :cascade do |t|
    t.integer "loan_officer_id", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.string "address_resolved"
    t.decimal "speed", precision: 6, scale: 2
    t.integer "battery_level"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_officer_id"], name: "index_gps_pings_on_loan_officer_id"
  end

  create_table "installments", force: :cascade do |t|
    t.integer "loan_id", null: false
    t.integer "installment_number", null: false
    t.date "due_date", null: false
    t.decimal "amount_due", precision: 12, scale: 2, null: false
    t.decimal "amount_paid", precision: 12, scale: 2, default: "0.0", null: false
    t.string "status", default: "pending", null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_installments_on_loan_id"
  end

  create_table "loan_officers", force: :cascade do |t|
    t.string "document_number", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.string "role", default: "collector", null: false
    t.string "motorcycle_plate"
    t.string "pin_code"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_number"], name: "index_loan_officers_on_document_number", unique: true
  end

  create_table "loans", force: :cascade do |t|
    t.string "loan_number", null: false
    t.integer "borrower_id", null: false
    t.integer "loan_officer_id", null: false
    t.integer "collection_route_id"
    t.decimal "principal_amount", precision: 12, scale: 2, null: false
    t.decimal "interest_rate_percent", precision: 5, scale: 2, default: "20.0", null: false
    t.decimal "insurance_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.integer "installment_count", default: 30, null: false
    t.string "installment_frequency", default: "daily", null: false
    t.decimal "installment_amount", precision: 12, scale: 2, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.decimal "balance_due", precision: 12, scale: 2, null: false
    t.integer "overdue_installments_count", default: 0, null: false
    t.decimal "overdue_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "status", default: "active", null: false
    t.datetime "disbursed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["borrower_id"], name: "index_loans_on_borrower_id"
    t.index ["collection_route_id"], name: "index_loans_on_collection_route_id"
    t.index ["loan_number"], name: "index_loans_on_loan_number", unique: true
    t.index ["loan_officer_id"], name: "index_loans_on_loan_officer_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "receipt_number", null: false
    t.integer "loan_id", null: false
    t.integer "loan_officer_id", null: false
    t.decimal "amount_paid", precision: 12, scale: 2, null: false
    t.decimal "previous_balance", precision: 12, scale: 2, null: false
    t.decimal "new_balance", precision: 12, scale: 2, null: false
    t.datetime "payment_date", null: false
    t.boolean "printed_thermal_receipt", default: false, null: false
    t.boolean "sms_sent", default: false, null: false
    t.string "signature_image_path"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_payments_on_loan_id"
    t.index ["loan_officer_id"], name: "index_payments_on_loan_officer_id"
    t.index ["receipt_number"], name: "index_payments_on_receipt_number", unique: true
  end

  create_table "penalties", force: :cascade do |t|
    t.integer "loan_id", null: false
    t.integer "loan_officer_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "reason", null: false
    t.datetime "applied_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_penalties_on_loan_id"
    t.index ["loan_officer_id"], name: "index_penalties_on_loan_officer_id"
  end

  create_table "vehicle_expenses", force: :cascade do |t|
    t.integer "loan_officer_id", null: false
    t.string "expense_type", default: "fuel", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "odometer_reading"
    t.string "notes"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_officer_id"], name: "index_vehicle_expenses_on_loan_officer_id"
  end

  add_foreign_key "cash_reconciliations", "loan_officers"
  add_foreign_key "co_signers", "borrowers"
  add_foreign_key "collection_routes", "loan_officers"
  add_foreign_key "gps_pings", "loan_officers"
  add_foreign_key "installments", "loans"
  add_foreign_key "loans", "borrowers"
  add_foreign_key "loans", "collection_routes"
  add_foreign_key "loans", "loan_officers"
  add_foreign_key "payments", "loan_officers"
  add_foreign_key "payments", "loans"
  add_foreign_key "penalties", "loan_officers"
  add_foreign_key "penalties", "loans"
  add_foreign_key "vehicle_expenses", "loan_officers"
end
