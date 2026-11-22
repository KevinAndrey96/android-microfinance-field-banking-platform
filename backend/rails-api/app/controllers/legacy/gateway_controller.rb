module Legacy
  class GatewayController < ApplicationController
    # Skip CSRF for legacy mobile Android client
    skip_before_action :verify_authenticity_token, raise: false

    # POST /Golden/login.php
    def login
      doc = params[:username] || params[:Dato1]
      pin = params[:password23] || params[:password] || params[:Contraseña]

      officer = LoanOfficer.find_by(document_number: doc)
      if officer && (officer.pin_code.blank? || officer.pin_code == pin)
        render json: {
          success: 1,
          message: "Autenticación exitosa",
          nombre: officer.name,
          permis3: "Línea de Supervisión Tolima: 310-449-8800"
        }
      else
        render json: {
          success: 0,
          message: "Credenciales inválidas"
        }
      end
    end

    # POST /Golden/credito.php
    def create_credit
      borrower_doc = params[:Dato1].to_s.strip
      valor = params[:Dato2].to_f
      # In legacy app, if valor is sent without trailing zeros (e.g. 500 = $500,000)
      valor = valor * 1000 if valor > 0 && valor < 10000

      cuotas = (params[:Dato3] || 30).to_i
      seguro = (params[:Dato4] || 0).to_f
      signo = params[:Dato7].to_s
      tipo = (params[:Dato8] || "Diario").to_s.downcase
      cobrador_doc = params[:Dato9].to_s.strip

      frequency = case tipo
                  when /semanal/ then "weekly"
                  when /quincenal/ then "biweekly"
                  when /mensual/ then "monthly"
                  else "daily"
                  end

      borrower = Borrower.find_by(document_number: borrower_doc)
      borrower ||= Borrower.create!(
        document_number: borrower_doc,
        first_name: "Cliente",
        last_name: borrower_doc,
        zodiac_sign: signo,
        city: "Ibagué",
        status: "active"
      )

      officer = LoanOfficer.find_by(document_number: cobrador_doc) || LoanOfficer.first

      loan = LoanOriginationService.call(
        borrower: borrower,
        loan_officer: officer,
        principal_amount: valor,
        installment_count: cuotas,
        frequency: frequency,
        insurance_amount: seguro
      )

      render json: {
        success1: 1,
        message1: "Crédito #{loan.loan_number} aprobado y desembolsado exitosamente"
      }
    rescue StandardError => e
      render json: {
        success1: 0,
        message1: "Error en desembolso: #{e.message}"
      }
    end

    # POST /Golden/envio.php
    def record_payment
      borrower_doc = params[:Dato1].to_s.strip
      amount = params[:Dato2].to_f
      amount = amount * 1000 if amount > 0 && amount < 10000

      cobrador_doc = params[:Dato3].to_s.strip
      pin = params[:Dato4].to_s.strip

      loan = Loan.find_by(loan_number: pin)
      loan ||= Borrower.find_by(document_number: borrower_doc)&.active_loan

      officer = LoanOfficer.find_by(document_number: cobrador_doc) || LoanOfficer.first

      if loan.nil?
        render json: { success: 0, message: "Crédito no encontrado" }
        return
      end

      payment = PaymentProcessingService.call(
        loan: loan,
        loan_officer: officer,
        amount: amount,
        printed_thermal: true,
        sms_sent: true
      )

      render json: {
        success: 1,
        message: "Pago de $#{amount.to_i} aplicado. Recibo #{payment.receipt_number}"
      }
    rescue StandardError => e
      render json: { success: 0, message: "Error al registrar pago: #{e.message}" }
    end

    # POST /Golden/ObtenerDatosPago.php
    def payment_receipt_data
      query = params[:pala].to_s.strip
      parts = query.split("-")
      pin = parts.last
      doc = parts.first

      loan = Loan.find_by(loan_number: pin)
      loan ||= Loan.find_by(loan_number: query)
      loan ||= Borrower.find_by(document_number: doc)&.active_loan
      loan ||= Loan.active.first

      if loan
        b = loan.borrower
        render json: {
          success: 1,
          empresas: [
            {
              Dato1: loan.insurance_amount.to_i.to_s,
              Dato2: b.zodiac_sign || "Aries",
              Dato3: loan.balance_due.to_i.to_s,
              Dato4: loan.remaining_installments_count.to_s,
              Dato5: loan.total_amount.to_i.to_s,
              Dato6: b.phone || "3100000000",
              Dato7: b.full_name,
              Dato8: loan.status == "in_arrears" ? "SI" : "NO",
              Dato9: loan.overdue_installments_count.to_s,
              Dato10: loan.start_date.strftime("%Y-%m-%d")
            }
          ]
        }
      else
        render json: { success: 0, message: "Datos no encontrados" }
      end
    end

    # POST /Golden/valorcuota.php
    def installment_value
      query = params[:pala].to_s.strip
      loan = Loan.find_by(loan_number: query) || Borrower.find_by(document_number: query)&.active_loan || Loan.active.first

      val = loan ? loan.installment_amount.to_i : 20000
      render json: {
        success: 1,
        empresas: [{ valor: val.to_s }]
      }
    end

    # POST /Golden/envia_ubicacion.php
    def track_location
      coords = params[:Coord].to_s.split(",")
      lat = coords.first.to_f
      lng = coords.last.to_f
      doc = params[:Docum].to_s.strip
      dir = params[:Dire].to_s

      officer = LoanOfficer.find_by(document_number: doc) || LoanOfficer.first

      if officer && lat != 0.0 && lng != 0.0
        GpsPing.create!(
          loan_officer: officer,
          latitude: lat,
          longitude: lng,
          address_resolved: dir,
          recorded_at: Time.current
        )
      end

      render json: { success: 1, message: "Telemetría GPS registrada exitosamente" }
    end

    # POST /Golden/gasolina.php
    def fuel_expense
      kilos = params[:Dato1].to_i
      valor = params[:Dato2].to_f
      doc = params[:Dato3].to_s.strip

      officer = LoanOfficer.find_by(document_number: doc) || LoanOfficer.first
      VehicleExpense.create!(
        loan_officer: officer,
        expense_type: "fuel",
        amount: valor,
        odometer_reading: kilos,
        recorded_at: Time.current
      )

      # Track expense in daily cash reconciliation
      rec = CashReconciliation.find_or_create_by!(loan_officer: officer, reconciliation_date: Date.current)
      rec.increment!(:total_expenses, valor)
      rec.compute_expected_closing!

      render json: { success1: 1, message1: "Gasto de combustible registrado" }
    end

    # POST /Golden/gastos.php
    def route_expense
      valor = params[:Dato1].to_f
      doc = params[:Dato2].to_s.strip
      motivo = params[:Dato3].to_s

      officer = LoanOfficer.find_by(document_number: doc) || LoanOfficer.first
      VehicleExpense.create!(
        loan_officer: officer,
        expense_type: "general",
        amount: valor,
        notes: motivo,
        recorded_at: Time.current
      )

      rec = CashReconciliation.find_or_create_by!(loan_officer: officer, reconciliation_date: Date.current)
      rec.increment!(:total_expenses, valor)
      rec.compute_expected_closing!

      render json: { success1: 1, message1: "Gasto de ruta registrado" }
    end

    # POST /Golden/envia_caja.php
    def cash_reconciliation
      valor = params[:Dato1].to_f
      doc = params[:Dato2].to_s.strip
      tipo = params[:Dato3].to_s.downcase

      officer = LoanOfficer.find_by(document_number: doc) || LoanOfficer.first
      rec = CashReconciliation.find_or_create_by!(loan_officer: officer, reconciliation_date: Date.current)

      case tipo
      when "recoger"
        rec.increment!(:total_collected, valor)
      when "entregar"
        rec.increment!(:opening_balance, valor)
      when "sueldo"
        rec.increment!(:salary_advance, valor)
      end
      rec.compute_expected_closing!

      render json: { success1: 1, message1: "Operación de caja ejecutada correctamente" }
    end

    # POST /Golden/lista_consultacaja.php
    def cash_reconciliation_summary
      doc = params[:pala].to_s.strip
      officer = LoanOfficer.find_by(document_number: doc) || LoanOfficer.first
      rec = CashReconciliation.find_or_create_by!(loan_officer: officer, reconciliation_date: Date.current)
      rec.compute_expected_closing!

      render json: {
        success: 1,
        empresas: [
          {
            Dato1: rec.opening_balance.to_i.to_s,
            Dato2: rec.total_collected.to_i.to_s,
            Dato3: rec.total_disbursed.to_i.to_s,
            Dato4: rec.total_expenses.to_i.to_s,
            Dato5: rec.salary_advance.to_i.to_s,
            Dato6: rec.closing_balance.to_i.to_s
          }
        ]
      }
    end

    # POST /Golden/rutas.php, rutassemanales.php, etc.
    def collection_route_items
      frequency = action_name_to_frequency

      loans = Loan.active.where(installment_frequency: frequency).includes(:borrower)
      data = loans.map do |l|
        b = l.borrower
        {
          Dato1: b.document_number,
          Dato2: b.full_name,
          Dato3: b.phone || "3100000000",
          Dato4: "#{b.address}, #{b.neighborhood}",
          Dato5: l.loan_number,
          Dato6: l.balance_due.to_i.to_s,
          Dato7: l.installment_amount.to_i.to_s,
          Dato8: l.status == "in_arrears" ? "SI" : "NO",
          Dato9: l.overdue_installments_count.to_s
        }
      end

      render json: {
        success: 1,
        empresas: data
      }
    end

    # POST /Golden/verclientes.php
    def borrowers_list
      data = Borrower.all.limit(100).map do |b|
        {
          Dato1: b.document_number,
          Dato2: b.full_name,
          Dato3: b.phone || "",
          Dato4: b.address || "",
          Dato5: b.city
        }
      end

      render json: {
        success: 1,
        empresas: data
      }
    end

    # POST /Golden/bloqueo.php
    def block_borrower
      doc = params[:pala].to_s.strip
      borrower = Borrower.find_by(document_number: doc)
      if borrower
        new_status = borrower.status == "blocked" ? "active" : "blocked"
        borrower.update!(status: new_status)
        render json: { success: 1, message: "Cliente actualizado a #{new_status}" }
      else
        render json: { success: 0, message: "Cliente no encontrado" }
      end
    end

    private

    def action_name_to_frequency
      case action_name
      when "weekly_routes" then "weekly"
      when "biweekly_routes" then "biweekly"
      when "monthly_routes" then "monthly"
      else "daily"
      end
    end
  end
end
