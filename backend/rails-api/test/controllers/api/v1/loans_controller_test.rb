require "test_helper"

class ApiV1LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @officer = LoanOfficer.create!(
      document_number: "333111222",
      name: "Diana Test",
      role: "collector",
      pin_code: "1234"
    )
    @borrower = Borrower.create!(
      document_number: "999888777",
      first_name: "Esteban",
      last_name: "Quintero",
      city: "Ibagué",
      status: "active"
    )
    @loan = LoanOriginationService.call(
      borrower: @borrower,
      loan_officer: @officer,
      principal_amount: 800_000,
      installment_count: 30,
      frequency: "daily"
    )
  end

  test "GET /api/v1/loans lists loans" do
    get "/api/v1/loans"
    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.any? { |l| l["loan_number"] == @loan.loan_number }
  end

  test "GET /api/v1/loans/:id shows loan details" do
    get "/api/v1/loans/#{@loan.loan_number}"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @loan.loan_number, json["loan_number"]
    assert json["installments"].present?
  end

  test "POST /api/v1/loans originates new loan via REST" do
    new_borrower = Borrower.create!(
      document_number: "777666555",
      first_name: "Patricia",
      last_name: "Vega",
      city: "Espinal",
      status: "active"
    )

    post "/api/v1/loans", params: {
      borrower_document: "777666555",
      loan_officer_document: "333111222",
      principal_amount: 400_000,
      installment_count: 20,
      frequency: "daily"
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json["loan_number"].present?
    assert_equal "480000.0", json["total_amount"].to_s
  end
end
