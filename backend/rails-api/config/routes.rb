Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # RESTful JSON API v1
  namespace :api do
    namespace :v1 do
      resources :loans, only: %i[index show create]
      resources :payments, only: %i[index create]
      resources :borrowers, only: %i[index show create]
      resources :cash_reconciliations, only: %i[index] do
        collection do
          get :today
        end
      end
      resources :gps_tracking, only: %i[index create]
    end
  end

  # Legacy Compatibility Gateway for Android Field Collector App
  scope :Golden, module: :legacy do
    post "login.php", to: "gateway#login"
    post "credito.php", to: "gateway#create_credit"
    post "envio.php", to: "gateway#record_payment"
    post "ObtenerDatosPago.php", to: "gateway#payment_receipt_data"
    post "valorcuota.php", to: "gateway#installment_value"
    post "envia_ubicacion.php", to: "gateway#track_location"
    post "gasolina.php", to: "gateway#fuel_expense"
    post "gastos.php", to: "gateway#route_expense"
    post "envia_caja.php", to: "gateway#cash_reconciliation"
    post "lista_consultacaja.php", to: "gateway#cash_reconciliation_summary"
    post "rutas.php", to: "gateway#collection_route_items"
    post "rutassemanales.php", to: "gateway#collection_route_items", defaults: { action: "weekly_routes" }
    post "rutasquincenales.php", to: "gateway#collection_route_items", defaults: { action: "biweekly_routes" }
    post "rutasmensuales.php", to: "gateway#collection_route_items", defaults: { action: "monthly_routes" }
    post "verclientes.php", to: "gateway#borrowers_list"
    post "bloqueo.php", to: "gateway#block_borrower"
  end
end
