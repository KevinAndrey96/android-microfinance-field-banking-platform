require "test_helper"

class LegacyGatewayControllerTest < ActionDispatch::IntegrationTest
  setup do
    @officer = LoanOfficer.create!(
      document_number: "111000999",
      name: "Andrey Test",
      role: "collector",
      pin_code: "1234"
    )
    @borrower = Borrower.create!(
      document_number: "222333444",
      first_name: "Carlos",
      last_name: "Cliente",
      phone: "3112223344",
      address: "Calle 15 # 3-20",
      neighborhood: "Centro",
      city: "Ibagué",
      zodiac_sign: "Aries",
      status: "active"
    )
    @loan = LoanOriginationService.call(
      borrower: @borrower,
      loan_officer: @officer,
      principal_amount: 500_000,
      installment_count: 30,
      frequency: "daily",
      interest_rate_percent: 20.0
    )
  end

  test "POST /Golden/login.php authenticates collector" do
    post "/Golden/login.php", params: { username: "111000999", password23: "1234" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["success"]
    assert_equal "Andrey Test", json["nombre"]
  end

  test "POST /Golden/envio.php registers field payment" do
    post "/Golden/envio.php", params: {
      Dato1: "222333444",
      Dato2: "40", # 40,000 COP
      Dato3: "111000999",
      Dato4: @loan.loan_number
    }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["success"]
    assert_match(/Pago de \$40000 aplicado/, json["message"])
  end

  test "POST /Golden/ObtenerDatosPago.php returns receipt print data" do
    post "/Golden/ObtenerDatosPago.php", params: { pala: "#{@borrower.document_number}-#{@loan.loan_number}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["success"]
    assert json["empresas"].present?
    assert_equal "Aries", json["empresas"].first["Dato2"]
  end

  test "POST /Golden/envia_ubicacion.php stores telemetry" do
    assert_difference -> { GpsPing.count }, 1 do
      post "/Golden/envia_ubicacion.php", params: {
        Coord: "4.438889,-75.232222",
        Docum: "111000999",
        Dire: "Plaza 21, Ibagué"
      }
    end
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["success"]
  end

  test "POST /Golden/gasolina.php records fuel expense" do
    post "/Golden/gasolina.php", params: {
      Dato1: "25000",
      Dato2: "20000",
      Dato3: "111000999"
    }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["success1"]
  end
end
