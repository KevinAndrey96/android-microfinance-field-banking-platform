# Android Microfinance Field Banking Platform

[![CI Pipeline](https://github.com/KevinAndrey96/android-microfinance-field-banking-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/KevinAndrey96/android-microfinance-field-banking-platform/actions/workflows/ci.yml)
[![Ruby on Rails](https://img.shields.io/badge/Ruby%20on%20Rails-8.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![Android Native](https://img.shields.io/badge/Android-Java%20SDK-3DDC84?style=flat-square&logo=android&logoColor=white)](https://developer.android.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose%20Ready-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)
[![Bixolon](https://img.shields.io/badge/Hardware-Bixolon%20Bluetooth%20Printer-orange?style=flat-square)](https://www.bixolon.com/)

A full-stack, enterprise-grade Microfinance and Field Banking platform designed for doorstep lending operations, field debt collection, and financial accounting. Built to coordinate loan officers on motorcycles navigating commercial routes and municipal hubs in the Tolima region of Colombia (Ibagué, El Espinal, Melgar, Chaparral, Honda).

The system pairs a native Android field application (equipped with portable Bluetooth thermal receipt printing, live GPS telemetry, digital touchscreen signatures, and offline SMS fallback) with a high-performance Ruby on Rails 8 API backend orchestrating loan origination, dynamic amortization schedules, audit ledgers, fuel monitoring, and end-of-day cashbox reconciliation.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph FieldLayer["🏍️ Field Operations (Motorcycle Fleet)"]
        Officer["Loan Officer / Collector\n(Android Native Device)"]
        Printer["Bixolon SPP-R200/R300\n(Bluetooth SPP Thermal Receipt)"]
        GPS["Location Provider\n(Periodic GPS Coordinates)"]
        Canvas["Touchscreen Canvas\n(Digital Signature Capture)"]
        SMS["GSM Network\n(SmsManager Transaction Receipts)"]

        Officer --> Printer
        Officer --> GPS
        Officer --> Canvas
        Officer --> SMS
    end

    subgraph NetworkGateway["🌐 Network & API Layer"]
        Nginx["Reverse Proxy / SSL"]
        Router["Rails 8 API Router"]
        LegacyAdapter["Legacy Android Adapter\n(/Golden/*.php Gateway)"]
        V1Api["RESTful JSON API v1\n(/api/v1/*)"]

        Nginx --> Router
        Router --> LegacyAdapter
        Router --> V1Api
    end

    subgraph BusinessDomain["⚙️ Rails 8 Domain Services"]
        OriginationSvc["LoanOriginationService\n(20% Interest, Schedules, Insurance)"]
        PaymentSvc["PaymentProcessingService\n(Installment Waterfall, Balance Math)"]
        ReconciliationSvc["CashReconciliationService\n(Base Cash, Disbursed, Collected, Handover)"]
        TelemetrySvc["GpsTrackingService\n(Route Coordinates, Velocity, Geocoding)"]
        ExpenseSvc["VehicleExpenseService\n(Odometer & Fuel Consumption)"]
    end

    subgraph StorageLayer["💾 Data Persistence & Cache"]
        Postgres[("PostgreSQL 16\n(ACID Relational Engine)")]
        RedisCache[("Redis 7\n(Telemetry Buffering & Cache)")]
    end

    Officer -->|HTTP Multipart / JSON| Nginx
    LegacyAdapter --> BusinessDomain
    V1Api --> BusinessDomain
    BusinessDomain --> Postgres
    BusinessDomain --> RedisCache
```

---

## 📊 Domain Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    LOAN_OFFICER ||--o{ COLLECTION_ROUTE : manages
    LOAN_OFFICER ||--o{ LOAN : originates
    LOAN_OFFICER ||--o{ PAYMENT : collects
    LOAN_OFFICER ||--o{ GPS_PING : transmits
    LOAN_OFFICER ||--o{ CASH_RECONCILIATION : balances
    LOAN_OFFICER ||--o{ VEHICLE_EXPENSE : logs

    BORROWER ||--o{ LOAN : holds
    BORROWER ||--o{ CO_SIGNER : has
    COLLECTION_ROUTE ||--o{ LOAN : groups

    LOAN ||--o{ INSTALLMENT : generates
    LOAN ||--o{ PAYMENT : receives
    LOAN ||--o{ PENALTY : incurs

    LOAN_OFFICER {
        string document_number PK
        string name
        string role
        string motorcycle_plate
        string pin_code
        boolean active
    }

    BORROWER {
        string document_number PK
        string first_name
        string last_name
        string phone
        string address
        string neighborhood
        string city
        string zodiac_sign
        string status
    }

    LOAN {
        string loan_number PK
        decimal principal_amount
        decimal interest_rate_percent
        decimal insurance_amount
        decimal total_amount
        integer installment_count
        string installment_frequency
        decimal installment_amount
        decimal balance_due
        string status
    }

    PAYMENT {
        string receipt_number PK
        decimal amount_paid
        decimal previous_balance
        decimal new_balance
        datetime payment_date
        boolean printed_thermal_receipt
        boolean sms_sent
    }

    CASH_RECONCILIATION {
        date reconciliation_date
        decimal opening_balance
        decimal total_collected
        decimal total_disbursed
        decimal total_expenses
        decimal salary_advance
        decimal closing_balance
        string status
    }
```

---

## 🛠️ Key Modules & Field Engineering Highlights

### 1. Bluetooth Thermal Receipt Printing (Bixolon SPP)
* Connects directly via Bluetooth Serial Port Profile (SPP) with mobile belt printers (`BxlService`).
* Dynamically compiles and prints transaction receipts including:
  * Official Crediexpress Golden branding banner.
  * Customer identification and loan pin identifier.
  * Security challenge response (Zodiac sign verification).
  * Transaction timestamp, installment amount paid, and remaining capital balance.
  * Delinquency flags and collector identity tag.
  * Customer service helpline.

### 2. Live GPS Telemetry & Fleet Tracking
* Background location listener transmitting periodic latitude, longitude, and geocoded street addresses.
* Allows operations supervisors to visualize route compliance, route stops, and transit velocities across Tolima highways and rural municipal access roads.

### 3. Digital Touchscreen Signature Capture
* Custom landscape `CanvasView` enabling borrowers to sign loan origination contracts and payment vouchers directly on the collector's device with finger input, uploading vectorized bitmap evidence.

### 4. Amortization Engine & Waterfall Payment Processing
* Supports daily, weekly, biweekly, and monthly microcredit structures.
* Automatically schedules installment calendars, skipping non-banking days (Sundays).
* Cascading payment waterfall that clears the oldest overdue installments first and updates remaining principal balances atomically.

### 5. Motorcycle Fuel & Logistics Ledger
* Field tracking of motorcycle odometer readings (`odometer_reading`) and fuel expenditures, correlating distance traveled against collections achieved per route.

### 6. End-of-Day Cashbox Reconciliation (`Caja`)
* Computes financial balance at the end of each shift:
  $$\text{Closing Balance} = \text{Opening Base Cash} + \text{Collections} - \text{Disbursements} - \text{Expenses} - \text{Salary Advances}$$
* Guarantees zero cash leakage between field collectors and central administration.

---

## 📂 Monorepo Structure

```
android-microfinance-field-banking-platform/
├── apps/
│   └── android/                      # Native Android Field Collector Application (Java)
│       ├── app/
│       │   ├── src/main/java/        # 36 Activities, Bluetooth print drivers, GPS telemetry
│       │   ├── src/main/res/         # XML layouts, drawables, strings, color palettes
│       │   └── libs/                 # Bxlprint.jar, httpmime.jar, urlimageviewhelper.jar
│       ├── BixolonPrinterSampleCode/ # Reference hardware integration workspace
│       ├── build.gradle              # Android build configuration
│       └── settings.gradle
├── backend/
│   └── rails-api/                    # Modern Ruby on Rails 8.1 API Backend
│       ├── app/
│       │   ├── controllers/
│       │   │   ├── api/v1/           # Standard RESTful JSON endpoints (Loans, Payments, Borrowers)
│       │   │   └── legacy/           # Backward-compatible gateway for native Android app (.php)
│       │   ├── models/               # Domain entities (Loan, Borrower, Payment, CashReconciliation)
│       │   └── services/             # LoanOriginationService, PaymentProcessingService
│       ├── config/                   # Routes, database.yml, Puma, CORS configuration
│       ├── db/
│       │   ├── migrate/              # Database schema migrations
│       │   └── seeds.rb              # Realistic Tolima regional seed dataset
│       ├── test/                     # Minitest test suite (models, services, integration)
│       ├── Dockerfile                # Production-ready multi-stage container build
│       └── Gemfile                   # Rails 8, PostgreSQL, SQLite, Puma, Solid Queue
├── docker-compose.yml                # Multi-container orchestration (Rails API, PostgreSQL 16, Redis 7)
├── Makefile                          # Developer automation targets
└── README.md                         # Technical reference documentation
```

---

## 🚀 Quick Start Guide

### Prerequisites
* Docker & Docker Compose (v2)
* Alternatively: Ruby 3.2+ with Bundler installed locally

### Option A: Launch with Docker Compose (Recommended)

```bash
# 1. Clone repository
git clone git@github.com:KevinAndrey96/android-microfinance-field-banking-platform.git
cd android-microfinance-field-banking-platform

# 2. Launch database, redis, and API services
docker compose up -d

# 3. View container status
docker compose ps
```

The Rails 8 API backend is available at `http://localhost:3000`.

### Option B: Local Development Setup

```bash
cd backend/rails-api

# Install dependencies into local vendor bundle
bundle config set --local path 'vendor/bundle'
bundle install

# Prepare database and execute seeds
bundle exec rails db:prepare
bundle exec rails db:seed

# Launch Rails server
bundle exec rails server -p 3000
```

---

## 🧪 Automated Testing

The Ruby on Rails test suite verifies domain models, loan calculations, payment waterfalls, and HTTP gateway compatibility:

```bash
cd backend/rails-api
bundle exec rails test
```

All 13 tests pass with 50 assertions covering:
* Loan origination mathematical accuracy and installment generation.
* Risk policy compliance (blocked debtor rejection).
* Multi-installment payment cascading and balance updates.
* Full legacy gateway endpoint compatibility (`login.php`, `credito.php`, `envio.php`, `envia_ubicacion.php`, `gasolina.php`).

---

## 📜 License

This project is licensed under the MIT License.
