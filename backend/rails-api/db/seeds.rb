# Tolima Regional Microfinance Field Banking Dataset
puts "Seeding Microfinance Field Banking System (Tolima Region)..."

# 1. Loan Officers (Prestamistas & Cobradores en Moto)
officer_andrey = LoanOfficer.find_or_create_by!(document_number: "1110500123") do |o|
  o.name = "Andrey Herrera"
  o.phone = "3104498800"
  o.email = "andrey.herrera@crediexpressgolden.com.co"
  o.role = "supervisor"
  o.motorcycle_plate = "ABC-12D"
  o.pin_code = "1234"
  o.active = true
end

officer_carlos = LoanOfficer.find_or_create_by!(document_number: "1110456789") do |o|
  o.name = "Carlos Mendoza"
  o.phone = "3158872211"
  o.email = "carlos.mendoza@crediexpressgolden.com.co"
  o.role = "collector"
  o.motorcycle_plate = "XYZ-98E"
  o.pin_code = "4321"
  o.active = true
end

officer_diana = LoanOfficer.find_or_create_by!(document_number: "1110321654") do |o|
  o.name = "Diana Ramirez"
  o.phone = "3182239944"
  o.email = "diana.ramirez@crediexpressgolden.com.co"
  o.role = "collector"
  o.motorcycle_plate = "TOL-45F"
  o.pin_code = "5678"
  o.active = true
end

# 2. Collection Routes (Rutas de Cobro)
route_centro = CollectionRoute.find_or_create_by!(code: "RUTA-IBG-CENTRO") do |r|
  r.name = "Ruta Centro & Plaza La 21"
  r.zone = "Ibagué - Comuna 1 y 2"
  r.frequency = "daily"
  r.loan_officer = officer_carlos
  r.active = true
end

route_salado = CollectionRoute.find_or_create_by!(code: "RUTA-IBG-SALADO") do |r|
  r.name = "Ruta El Salado & Comuna 8"
  r.zone = "Ibagué - Comuna 7 y 8"
  r.frequency = "daily"
  r.loan_officer = officer_andrey
  r.active = true
end

route_espinal = CollectionRoute.find_or_create_by!(code: "RUTA-TOL-ESPINAL") do |r|
  r.name = "Ruta Comercio El Espinal"
  r.zone = "El Espinal - Centro y Terminal"
  r.frequency = "weekly"
  r.loan_officer = officer_diana
  r.active = true
end

# 3. Borrowers (Prestatarios / Comerciantes)
borrower_marta = Borrower.find_or_create_by!(document_number: "65789123") do |b|
  b.first_name = "Marta Lucía"
  b.last_name = "Gómez Pineda"
  b.phone = "3114567890"
  b.address = "Cra 4 # 21-45 Local 12"
  b.neighborhood = "Centro"
  b.city = "Ibagué"
  b.department = "Tolima"
  b.latitude = 4.438889
  b.longitude = -75.232222
  b.zodiac_sign = "Tauro"
  b.status = "active"
  b.notes = "Negocio de frutas y abarrotes en plaza de mercado La 21. Pagadora puntual."
end

borrower_jorge = Borrower.find_or_create_by!(document_number: "93389456") do |b|
  b.first_name = "Jorge Eliécer"
  b.last_name = "Castro Bocanegra"
  b.phone = "3139876543"
  b.address = "Mz B Casa 14"
  b.neighborhood = "El Salado"
  b.city = "Ibagué"
  b.department = "Tolima"
  b.latitude = 4.465000
  b.longitude = -75.185000
  b.zodiac_sign = "Leo"
  b.status = "active"
  b.notes = "Taller de mecánica de motos. Crédito diario."
end

borrower_gloria = Borrower.find_or_create_by!(document_number: "38245678") do |b|
  b.first_name = "Gloria Inés"
  b.last_name = "Varón Prada"
  b.phone = "3187654321"
  b.address = "Calle 10 # 6-30"
  b.neighborhood = "Centro"
  b.city = "El Espinal"
  b.department = "Tolima"
  b.latitude = 4.149167
  b.longitude = -74.883889
  b.zodiac_sign = "Virgo"
  b.status = "active"
  b.notes = "Miscelánea y papelería frente al parque principal. Modalidad semanal."
end

# Co-signers (Codeudores)
CoSigner.find_or_create_by!(document_number: "14234567", borrower: borrower_marta) do |c|
  c.name = "Hernando Gómez Pineda"
  c.phone = "3128899001"
  c.relationship = "Hermano"
  c.address = "Cra 3 # 22-10, Ibagué"
end

# 4. Loans & Amortization Schedules
loan1 = Loan.find_or_create_by!(loan_number: "PIN-10492") do |l|
  l.borrower = borrower_marta
  l.loan_officer = officer_carlos
  l.collection_route = route_centro
  l.principal_amount = 1_000_000.00
  l.interest_rate_percent = 20.0
  l.insurance_amount = 30_000.00
  l.total_amount = 1_230_000.00
  l.installment_count = 30
  l.installment_frequency = "daily"
  l.installment_amount = 41_000.00
  l.start_date = 10.days.ago.to_date
  l.end_date = 20.days.from_now.to_date
  l.balance_due = 1_230_000.00
  l.status = "active"
  l.disbursed_at = 10.days.ago
end

loan2 = Loan.find_or_create_by!(loan_number: "PIN-20845") do |l|
  l.borrower = borrower_jorge
  l.loan_officer = officer_andrey
  l.collection_route = route_salado
  l.principal_amount = 600_000.00
  l.interest_rate_percent = 20.0
  l.insurance_amount = 20_000.00
  l.total_amount = 740_000.00
  l.installment_count = 30
  l.installment_frequency = "daily"
  l.installment_amount = 24_667.00
  l.start_date = 15.days.ago.to_date
  l.end_date = 15.days.from_now.to_date
  l.balance_due = 740_000.00
  l.status = "active"
  l.disbursed_at = 15.days.ago
end

# Generate installments for loan1 if not present
if loan1.installments.empty?
  30.times do |i|
    loan1.installments.create!(
      installment_number: i + 1,
      due_date: loan1.start_date + (i + 1).days,
      amount_due: 41_000.00,
      amount_paid: 0.0,
      status: "pending"
    )
  end
end

# 5. Field Payments & Thermal Receipts
if loan1.payments.empty?
  PaymentProcessingService.call(
    loan: loan1,
    loan_officer: officer_carlos,
    amount: 164_000.00, # 4 cuotas
    payment_date: 2.days.ago,
    printed_thermal: true,
    sms_sent: true,
    latitude: 4.438889,
    longitude: -75.232222
  )
end

# 6. Motorcycle Telemetry (GPS Tracking)
GpsPing.find_or_create_by!(loan_officer: officer_carlos, recorded_at: 1.hour.ago) do |p|
  p.latitude = 4.439500
  p.longitude = -75.231800
  p.address_resolved = "Cra 4 con Calle 22, Ibagué"
  p.speed = 28.5
  p.battery_level = 82
end

GpsPing.find_or_create_by!(loan_officer: officer_andrey, recorded_at: 30.minutes.ago) do |p|
  p.latitude = 4.464100
  p.longitude = -75.186200
  p.address_resolved = "Calle 140 El Salado, Ibagué"
  p.speed = 34.0
  p.battery_level = 91
end

# 7. Fuel & Logistics Expenses
VehicleExpense.find_or_create_by!(loan_officer: officer_carlos, recorded_at: 1.day.ago) do |e|
  e.expense_type = "fuel"
  e.amount = 25_000.00
  e.odometer_reading = 34_520
  e.notes = "Tanqueo Terpel Cra 5 con Calle 25"
end

# 8. Daily Cash Reconciliation (Caja)
rec = CashReconciliation.find_or_create_by!(loan_officer: officer_carlos, reconciliation_date: Date.current) do |c|
  c.opening_balance = 300_000.00
  c.total_collected = 164_000.00
  c.total_disbursed = 0.0
  c.total_expenses = 25_000.00
  c.salary_advance = 50_000.00
  c.status = "open"
  c.notes = "Jornada matutina completada en Ruta Centro."
end
rec.compute_expected_closing!

puts "Seed finished successfully: 3 Officers, 3 Routes, 3 Borrowers, 2 Loans, Payments, GPS tracks, Fuel & Cash ledger."
