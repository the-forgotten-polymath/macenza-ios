# Rajputana Automobiles — iOS Application

Native iOS ERP companion and dealer portal for **Rajputana Automobiles**, a B2B automotive spare parts distributor in India. Built with **SwiftUI** and designed for iOS 17.0+.

The application integrates with the live Rajputana Automobiles REST API and synchronizes with **TallyPrime Enterprise** for inventory, orders, customer accounts, and financial ledgers.

---

## 📱 Features & Capabilities

### 1. Multi-Tenant Role Access
- **Super Admin**: Full visibility into monthly sales KPIs, gross sales trends, receivables aging, inventory thresholds, staff management, audit trail logs, watermark settings, and fine-grained role permission management (`api/roles`).
- **Admin**: Dynamically governed by the role permission matrix configured in Superadmin. Only displays tabs and actions authorized for the admin account.
- **Customer (Dealer Portal)**:
  - **Product Catalog**: Live search across SKUs/part numbers, category pills, responsive 2-column product grid with quantity steppers (`- [count] +`) and add-to-cart.
  - **Category Browser**: Expandable/collapsible accordion of system domains with 3-column subcategory grid.
  - **Orders**: Dual dropdown filters (Date Range & Order Status), live order status tracker, purchased line item rates, and one-tap reorder.
  - **Cart & Multi-Step Checkout**:
    - Real-time cart calculations with pack multipliers and item removal.
    - Order summary card (Subtotal, 18% GST, Free Shipping, Net Total).
    - Delivery address selection with "Add Address / Workshop Depot" modal.
    - **UPI App Deep Linking**: Direct deep links to **Google Pay**, **PhonePe**, **Paytm**, and **BHIM UPI** pre-filling beneficiary VPA, order note, transaction reference, and exact payable net amount.
  - **Customer Account Ledger**:
    - Dealer dossier card (`13 Traders, Beawar`, `13-raj-001`, `Beawar`).
    - 2×2 Metrics grid (`Opening Balance`, `Total Debits`, `Total Credits`, `Closing Balance` in Dr/Cr with status tinting).
    - `Pending This Period` summary card.
    - Interactive "Select Period" modal with `FY 2026-27` quick-select pill and custom date pickers.
    - Voucher list (`GST SALE`, `RECEIPT`, `GST PURCHASES`) with formal PDF download generation.
    - Period summary card.
  - **Notifications Center**: Unread badge count, live search, filter chips (`All`, `Unread`, `Orders`, `Security Login`), mark-all-as-read, and deep navigation into orders.

### 2. Architecture & Design System
- **Framework**: SwiftUI (100% native declarative UI).
- **Design System**: Liquid Glass theme matching Android Google Material 3 with adaptive cards, custom gradients, status tags, and SF Symbols.
- **Session Management**: Automatic 30-second heartbeat check (`api/auth/heartbeat`) with single-session enforcement, and foreground permission refresh every 5 minutes.
- **PDF Engine**: Client-side HTML-to-PDF rendering engine for official Tax Invoices, Receipt Vouchers, and Ledger Statements.

---

## 🚀 Getting Started

### Prerequisites
- **macOS Sonoma (14.0+)** or **macOS Sequoia (15.0+)**
- **Xcode 15.0+** or **Xcode 16.0+**
- **iOS 17.0+** Simulator or physical device

### Opening in Xcode
1. Clone the repository:
   ```bash
   git clone https://github.com/the-forgotten-polymath/macenza-ios.git
   cd macenza-ios
   ```
2. Open the Xcode project:
   ```bash
   open "Rajputana Automobiles.xcodeproj"
   ```
3. Select an iOS Simulator (e.g. **iPhone 17 Pro** or **iPhone 16 Pro**) from the scheme dropdown.
4. Press **⌘ + R** (or click **Product > Run**) to build and run the app.

---

## 🔑 Demo & Test Credentials

The login screen provides one-tap role buttons that automatically pre-fill demo credentials:

| Role | Username / Identifier | Password | Description |
|---|---|---|---|
| **Super Admin** | `superadmin@automob.in` | `superadmin123` | Full ERP governance, permissions, staff, and financial control. |
| **Admin** | `admin@automob.in` | `admin123` | Daily operational management (orders, customers, stock). |
| **Customer** | `13-raj-001` | `123456789` | Dealer portal for **13 Traders, Beawar** with orders and ledger. |

---

## 📂 Project Structure

```
.
├── Rajputana Automobiles.xcodeproj   # Xcode project bundle with shared scheme
├── Rajputana Automobiles/            # Swift source code and resources
│   ├── Assets.xcassets               # App logo, icons, colors, images
│   ├── ContentView.swift             # Root entry view and session router
│   ├── Rajputana_AutomobilesApp.swift# App lifecycle entry point
│   ├── Core/                         # Navigation shells, theme, network, storage
│   │   ├── Navigation/               # CustomerAppShell, MainAppShell, BottomNavBar
│   │   ├── Network/                  # APIEndpoint, NetworkService
│   │   ├── Storage/                  # SessionManager
│   │   └── Theme/                    # LiquidTheme, AppColors, Typography
│   ├── Features/                     # Functional modules
│   │   ├── Auth/                     # Login & credentials
│   │   ├── CustomerPortal/           # Catalog, Categories, Cart, Checkout
│   │   ├── Customers/                # Customer list, dossier, invoices
│   │   ├── Dashboard/                # Superadmin & Admin KPI dashboards
│   │   ├── Inventory/                # SKU stock, price editing, specs
│   │   ├── Ledgers/                  # Detailed ledger, vouchers, PDF generation
│   │   ├── Notifications/            # Top-bar notification sheet
│   │   ├── Orders/                   # Order list, approval, LR upload
│   │   ├── Settings/                 # Role permissions, brand assets, watermark
│   │   └── Staff/                    # Employee list, add/edit modal
│   ├── Models/                       # Strongly typed Codable data models
│   ├── Resources/                    # Static assets & mapping data
│   └── Services/                     # Singleton API services
├── docs/                             # Architecture blueprint & Android analysis
├── .gitignore                        # Xcode & macOS ignore rules
└── README.md                         # Project documentation
```

---

## 📄 License
Internal proprietary software for **Rajputana Automobiles**.
