# Rajputana Automobiles — Android Application Reverse Engineering & Analysis

> Comprehensive technical audit, feature inventory, API endpoint catalogue, and data architecture specification of the Rajputana Automobiles Android ERP App (`Rajputana-Automobile-Android-App-main`).

---

## 1. Executive Summary & Domain Overview

**Rajputana Automobiles** is a native mobile ERP companion designed for a B2B automotive spare parts distributor in India.
- **Core Domain:** Distribution and wholesale of auto spare parts (brakes, suspension, electrical, bearings, dampers, etc.) to registered dealers and workshops.
- **System of Record:** **TallyPrime Enterprise** manages inventory stock levels, customer parties, tax invoices, and accounting ledgers.
- **Backend Architecture:** Node.js / Express REST API (`https://api.rajputanaautomobiles.com/`) that continuously synchronizes with Tally and serves mobile clients.
- **Multi-Tenant User Roles:** 
  1. **Superadmin:** Full access to business analytics, customer management, inventory control, order dispatch, ledger statements, staff accounts, audit logs, and global company/security settings.
  2. **Admin / Ops Staff:** Operational access dynamically governed by a fine-grained backend permission matrix (`GET /api/roles`).
  3. **Customer (Dealer):** Dedicated B2B buyer portal allowing dealers to browse catalogue, inspect technical specifications, build server-synced carts, place orders with GST calculations, track orders with Lorry Receipts (LR), view account ledgers, and manage company profiles.

---

## 2. Complete Screen & Component Inventory

### 2.1 Authentication & Session
| Screen / Component | Type | Description & Capabilities |
|---|---|---|
| **LoginScreen** | Screen | Tab switcher for quick demo credentials (Super Admin, Admin, Customer/Dealer); fields for Email, Password, Device Info (`Android <version> \| <manufacturer> <model>`); "Keep me signed in" checkbox; Password visibility toggle; Session initiation via `POST /api/auth/login`. |
| **Session Heartbeat** | Background Coroutine | Runs every 30 seconds (`GET /api/auth/heartbeat`). Automatically forces logout if another device logs in under the same customer account or token expires. |
| **Foreground Permission Sync** | Lifecycle Trigger | Checks backend role matrix on `ON_START` at most once every 5 minutes (`GET /api/roles`), refreshing permissions in place without re-authenticating. |
| **AccessDeniedScreen** | Fallback View | Shown whenever a user attempts to navigate to a route not granted in their role permission matrix. |

---

### 2.2 Management Portal (Superadmin & Admin)

#### A. Dashboard
- **KPI Metrics Cards (4):**
  1. *Monthly Sales:* Sum of approved orders for the current month vs. previous month percentage trend. Target derived from previous month's invoice revenue × 1.10. Tapping navigates to Orders.
  2. *Outstanding Balance:* Total pending receivables from `GET /api/ledger/payment-due`.
  3. *Active Customers:* Total registered customer count from `GET /api/customers`.
  4. *Warehouse Stock:* Total physical units in stock + unique SKU count from `GET /api/inventory`.
- **Gross Sales Trends Chart:**
  - 7-month rolling line chart (`MPAndroidChart`).
  - Displays monthly Net Sales in Lakhs (₹0 – ₹150L capped Y-axis in 30L increments).
  - Plots Revenue vs. 110% Target line.
  - Interactive tooltip showing exact rupee amounts.
- **Receivables Aging Pie Chart:**
  - Buckets: 0–30 Days (Current/Green), 31–60 Days (Due Soon/Amber), 60+ Days (Overdue/Red).
  - Displays percentage breakdown and rupee amounts per bucket.
- **Recent System Activity Feed:**
  - Displays the 5 latest audit logs (`GET /api/activities`) with user avatars, actions, and timestamps.
  - Conditionally rendered only if role has `AUDIT_LOGS` view permission.
- **Parallel Data Loading:**
  - Fires 5 endpoints concurrently (`payment-due`, `orders`, `customers`, `inventory`, `invoices`) via Kotlin Coroutines.
  - Offloads intensive aggregations to background dispatchers (`Dispatchers.Default`).

#### B. Customers Module
- **CustomerScreen (List):**
  - Search by customer name, code, city, phone, or GSTIN.
  - Displays party name, code, city, outstanding balance with credit status badge, and quick action buttons ("View Statement", "Profile").
- **DetailedCustomerScreen (Detail):**
  - Comprehensive customer dossier: Contact person, phone, email, full billing address, GSTIN, credit limit, payment terms, outstanding balance, price tier.
  - Quick action bar: Call customer, email, view ledger, edit profile, delete customer.
  - Invoices sub-tab: Chronological list of tax invoices issued to this party.
- **EditCustomerBottomSheet:**
  - Bottom sheet modal for updating customer address, contact phone, email, credit limit, payment terms, price tier, and password override.
- **DeleteConfirmationDialog:**
  - Destructive confirmation dialog before executing `DELETE /api/customers/{id}`.

#### C. Orders Module (Management)
- **OrdersScreen (List):**
  - Filter chips: `All`, `Confirmed` (New), `Approved`, `Synced`, `Dispatched`, `Delivered`, `Rejected`.
  - Order cards: Order number, customer name, date, total amount, item count, status badge, LR indicator ("LR Ready" vs "Pending").
- **OrderDetailScreen (Detail):**
  - Order header with status tag, order ID, placement date.
  - Quick action toolbar: **Approve** and **Reject** buttons (updates status via `PUT /api/orders/{id}/status`).
  - Line items breakdown: Product name, SKU/part number, rate, ordered quantity, subtotal.
  - Tax & Total breakdown: Subtotal, 18% GST, complimentary freight, Net Payable.
  - Delivery information: Recipient name, full shipping address, contact phone.
  - **Lorry Receipt (LR) Card:** Displays transporter name, vehicle number, LR document name, size, upload timestamp, notes. Includes buttons to Download LR or Replace/Delete.
  - **Print Invoice:** Off-screen WebView renderer that prints/saves formal tax invoice PDF.
- **LrBottomSheet:**
  - Modal form to upload transport receipt: LR Number, Transporter Name, Vehicle Number, Transport Notes.
  - File picker (PDF, JPG, PNG up to 10 MB). Encodes file to base64 Data URI with 120-second network write timeout.

#### D. Inventory Module
- **InventoryScreen (List):**
  - Search bar across part numbers, OEM codes, item names, descriptions, and vehicle applications.
  - Filter chips by vehicle segment (4-Wheeler, 2-Wheeler) and category.
  - Inventory card: Product image with fallback, part number, product title, category line (`primaryGroup · stockGroup`), warehouse location, stock level with warning threshold badge (Red if stock <= minThreshold), dealer price.
  - Actions: Quick edit bottom sheet, view detailed specs, trigger Tally Sync.
- **InventoryDetailScreen (Detail):**
  - Multi-image carousel with zoom capability.
  - Pricing matrix: Dealer Price, Retail Price, Wholesale Price, Customer Price, Closing Value.
  - Stock details: Current stock level, reorder threshold, unit of measurement (Pcs/Sets), GST rate.
  - Technical Specifications table (Key-Value pairs).
  - Product Description sheet.
  - Manage Photos modal (add via camera/gallery, reorder, delete).
- **QuickEditInventoryBottomSheet:** Inline stock and pricing adjustment modal.
- **EditSpecificationsBottomSheet:** Dynamic key-value pairs editor for technical attributes.
- **EditDescriptionBottomSheet:** Rich text description editor.
- **ManagePhotosBottomSheet:** Image gallery manager with base64 upload (`POST /api/inventory/{id}/upload-image`).
- **DeleteInventoryDialog:** Confirmation modal for deleting catalog items.

#### E. Ledgers & Financials
- **CustomerLedgerFinanceScreen (Summary):**
  - Master summary list of all party accounts.
  - Displays Opening Balance, Debit Total, Credit Total, Closing Balance with Dr/Cr indicator.
  - Search by customer/party name.
- **DetailedLedgerScreen (Party Statement):**
  - Date range filters (Current Month, Last Quarter, Financial Year, Custom Range).
  - Chronological transaction vouchers table (Sales Invoices, Receipt Vouchers, Credit Notes, Journals).
  - Bills Receivable list (unpaid invoices with aging days).
  - Running balance calculations.
  - Export statement as PDF via Android print engine.

#### F. Staff Management
- **StaffScreen (List):**
  - List of employees / internal operators: Name, role badge (Admin, Manager, Staff), employee ID, department, status (Active/Inactive), phone, email.
- **AddEditStaffBottomSheet:**
  - Create / update staff form: Employee ID, Full Name, Email, Phone, Role selector, Department, Designation, Office Address.
  - State & District dropdown powered by local `states_and_cities.json` asset.
- **DeleteStaffDialog:** Modal confirmation for deleting staff account.

#### G. Audit Logs
- **AuditLogsScreen:**
  - Read-only historical audit trail.
  - Categorized log cards: Event Type, Action Title, Description, Responsible User, Timestamp.
  - Event filter chips: All, Authentication, Orders, Inventory, System.

#### H. Settings (Superadmin Only)
- **SettingsScreen:**
  - **Company Profile Tab:** Organization name, tagline, GSTIN, support email, phone, registered office address, logo upload, Tally sync status.
  - **Watermark Settings Tab:** Image watermark upload, opacity slider (0–100%), scale percentage, position selector (bottom-right, center, etc.).
  - **Roles & Permissions Tab:** Role switcher, matrix editor for all modules (`Orders`, `Customers`, `Inventory`, `Financials`, `Staff`, `Audit Logs`, `Settings`) with `View` and `Edit` toggle switches. Bulk save button.
  - **Customer Password Override Tab:** Admin utility to reset passwords for dealers locked out of their accounts.

---

### 2.3 Customer / Dealer Portal

#### A. Customer Home / Catalogue (`CatalogScreen`)
- **Customer Toolbar:** Company logo, search shortcut, notification bell with unread badge, shopping cart icon with live item count badge.
- **Welcome Banner:** Displays dealer business name and active price tier.
- **Featured Categories Section:** 5 curated high-volume categories:
  1. *Assembly*
  2. *Blinkers*
  3. *Bosch Limited*
  4. *Bosch Others*
  5. *Damper*
  - "View All Categories" action button navigating to the full category hierarchy.
- **Featured Products Grid:**
  - 2-column responsive grid of products.
  - Thumbnail, part number, product title, manufacturer badge, dealer price (₹), box pack quantity, in-stock badge.
  - Direct "Add to Cart" button with client-side stock availability verification and snackbar notifications.

#### B. Categories & Product Browsing
- **CustomerCategoryScreen (Master Categories):**
  - Expandable / collapsible accordion list of **System Domains** (e.g., *Suspension*, *Braking*, *Electrical*, *Engine*, *Body Parts*).
  - Sub-categories nested under each domain with item counts.
- **CustomerCategoryDetailScreen (Category Products):**
  - Product grid specific to the selected Domain + Category combination.
  - Quick search and filtering within category.
- **CustomerProductDetailScreen (Product Page):**
  - High-resolution image carousel with pinch-to-zoom.
  - Product specifications table (dimensions, vehicle fitment, warranty, OEM codes).
  - Pricing box showing Dealer Net Price, GST breakdown (18%), and Minimum Order Pack.
  - Interactive Quantity Stepper with real-time stock cap enforcement.
  - "Add to Cart" and "Buy Now" CTAs.

#### C. Shopping Cart & 4-Step Checkout (`CartFlowScreen`)
The customer checkout is implemented as a synchronized multi-step stepper:
1. **Step 1: Cart Review (`CartStepScreen`)**
   - Live server-backed cart (`GET /api/cart?identifier={id}`).
   - Item cards with quantity stepper (`+` / `-`), pack multiplier, and item removal.
   - Price summary card: Subtotal, GST (18%), Complimentary Freight badge, Total Net Amount.
2. **Step 2: Delivery Address (`AddressStepScreen`)**
   - Selection of saved delivery depots / workshop addresses.
   - **AddAddressBottomSheet:** Form to add recipient name, street address, city, state, pincode, phone number, GSTIN.
3. **Step 3: Payment Preview (`PaymentStepScreen`)**
   - UPI Payment info preview (Beneficiary Name, UPI ID `rajputana.auto@icici`, QR payload deep link).
   - Order confirmation disclaimer before final submission.
4. **Step 4: Order Confirmation (`ConfirmationStepScreen`)**
   - Order placement API execution (`POST /api/orders`) with specialized ERP headers.
   - Animated checkmark celebration.
   - Displays newly generated Order Number (e.g., `ORD-2026-1049`).
   - Automated cart cleanup (`DELETE /api/cart`).
   - 10-second auto-redirect countdown to home catalogue, or "View Order Details" button.

#### D. Customer Orders & Reorder
- **OrderListScreen:**
  - List of past orders placed by this customer (filtered by `customerCode` / `customerEmail`).
  - Status badges: `Confirmed`, `Approved`, `Synced`, `Dispatched`, `Delivered`.
  - Date, total order value, item count.
- **OrderDetailsScreen:**
  - Order progression tracker.
  - Purchased line items with invoice rates.
  - Transport & Lorry Receipt (LR) details if dispatched.
  - **One-Tap Reorder:** Reads order items, checks current stock availability in inventory, matches current pricing, and pushes available items into the live cart in a single batch request.

#### E. Customer Ledger & Profile
- **Customer Ledger:** Read-only view of the dealer's financial ledger statement directly from Tally, showing outstanding balance and bills.
- **CustomerProfileScreen:**
  - Dealer business dossier: Business name, dealer code, GSTIN, registered address, primary contact.
  - Avatar image with camera/gallery upload.
  - Change Password form (`POST /api/auth/change-password`).
  - Session sign-out.

---

### 2.4 Notifications (Shared Module)
- **NotificationScreen:**
  - Filter chips: `All`, `Unread` (`read == false`), `Orders` (`type` contains "order"), `Security` (`type == "customer_login_alert"`).
  - Notification items: Severity indicator (info, success, warning, error), title, message, formatted date/time, read status.
  - Swipable / contextual actions: Mark as Read, Mark as Done, Delete.
  - Header actions: "Mark All as Read", "Clear Done".
  - Interactive deep links:
    - Order notification -> opens relevant order detail screen.
    - Security / Login alert -> opens customer dossier or profile.
- **Badge Polling:** Polled every 2 minutes via `AppShellViewModel` to keep the top-bar badge count synchronized.

---

## 3. Backend Endpoints Catalogue (51 APIs)

All requests point to `https://api.rajputanaautomobiles.com/` and automatically receive the `Authorization: Bearer <token>` header (except `POST api/auth/login`).

### 3.1 Authentication & Session (7 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 1 | `POST` | `api/auth/login` | `{ email, password, deviceInfo }` | `{ message, token, role, user: { id, code, name, email, phone, address, gstin, role, companyName } }` | `AuthApi.login` |
| 2 | `GET` | `api/auth/heartbeat` | Header: `Authorization: Bearer <token>` | `{ valid: Boolean, code?, message? }` | `AuthApi.heartbeat` |
| 3 | `POST` | `api/auth/logout` | Header: `Authorization: Bearer <token>` | `{ success: Boolean, message? }` | `AuthApi.logout` |
| 4 | `GET` | `api/auth/profile` | Query: `role`, `email` | `{ success: Boolean, user: StaffProfileDto }` | `AuthApi.getProfile` |
| 5 | `PUT` | `api/auth/profile` | `UpdateAuthProfileRequest` | `StaffProfileResponse` | `AuthApi.updateProfile` |
| 6 | `POST` | `api/auth/change-password` | `{ identifier, oldPassword, newPassword }` | `{ success: Boolean, message? }` | `AuthApi.changePassword` |
| 7 | `POST` | `api/auth/upload-avatar` | `{ avatarUrl, role, email, identifier? }` | `{ success: Boolean, message?, avatarUrl }` | `AuthApi.uploadStaffAvatar` |

### 3.2 Roles & Permissions (4 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 8 | `GET` | `api/roles` | Optional Header: `Authorization` | `List<RoleResponse>` | `RoleApi.getRoles` |
| 9 | `POST` | `api/roles` | `CreateRoleRequest{ name, description?, permissions, createdBy? }` | `RoleResponse` | `RoleApi.createRole` |
| 10 | `PUT` | `api/roles/matrix/bulk-save` | `BulkSaveRequest{ roles, permissionsMap }` | `BulkSaveResponse{ success, message, roles }` | `RoleApi.bulkSaveMatrix` |
| 11 | `DELETE` | `api/roles/{id}` | Path: `{id}` | `DeleteRoleResponse{ success, message }` | `RoleApi.deleteRole` |

### 3.3 Company & Settings (2 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 12 | `GET` | `api/company` | None | `CompanyProfile` | `CompanyApi.getCompany` |
| 13 | `PUT` | `api/company` | `CompanyProfile` | `CompanyProfile` | `CompanyApi.updateCompany` |

### 3.4 Staff Management (5 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 14 | `GET` | `api/staff` | None | `List<StaffModel>` | `StaffApi.getStaff` |
| 15 | `GET` | `api/staff/{id}` | Path: `{id}` | `StaffModel` | `StaffApi.getStaffById` |
| 16 | `POST` | `api/staff` | `StaffRequest` | `StaffModel` | `StaffApi.createStaff` |
| 17 | `PUT` | `api/staff/{id}` | Path: `{id}`, Body: `StaffRequest` | `StaffModel` | `StaffApi.updateStaff` |
| 18 | `DELETE` | `api/staff/{id}` | Path: `{id}` | `DeleteStaffResponse{ success, message }` | `StaffApi.deleteStaff` |

### 3.5 Customers & Invoices (7 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 19 | `GET` | `api/customers` | None | `List<Customer>` | `CustomerApi.getCustomers` |
| 20 | `GET` | `api/customers/{id}` | Path: `{id}` | `CustomerDetailModel` | `CustomerApi.getCustomerById` |
| 21 | `PUT` | `api/customers/{id}` | Path: `{id}`, Body: `EditCustomerRequest` | `CustomerDetailModel` | `CustomerApi.updateCustomer` |
| 22 | `POST` | `api/customers/{id}/upload-avatar` | Path: `{id}`, Body: `CustomerAvatarUploadRequest` | `CustomerAvatarUploadResponse` | `CustomerApi.uploadCustomerAvatar` |
| 23 | `DELETE` | `api/customers/{id}` | Path: `{id}` | `DeleteCustomerResponse{ success, id }` | `CustomerApi.deleteCustomer` |
| 24 | `GET` | `api/ledger/invoices` | None | `List<Invoice>` | `InvoiceApi.getInvoices` |
| 25 | `GET` | `api/ledger/invoices/{invoiceNumber}` | Path: `{invoiceNumber}` (encoded), Query: `party?` | Raw `JsonElement` (`InvoiceDetailParser`) | `InvoiceApi.getInvoiceDetail` |

### 3.6 Ledgers & Financials (3 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 26 | `GET` | `api/ledger/summary` | None | `List<LedgerSummary>` | `LedgerSummaryApi.getSummary` |
| 27 | `GET` | `api/ledger/customer/{customerName}` | Path: `{customerName}` (encoded) | `LedgerResponse` | `LedgerApi.getLedger` |
| 28 | `GET` | `api/ledger/payment-due` | None | `PaymentDueResponse{ totalOutstanding, agingBuckets }` | `PaymentDueApi.getPaymentDue` |

### 3.7 Inventory & Stock (8 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 29 | `GET` | `api/inventory` | Query: `nocache?` | `List<InventoryItem>` (~7,500 items) | `InventoryApi.getInventory` |
| 30 | `GET` | `api/inventory/{id}` | Path: `{id}`, Query: `nocache?` | `InventoryItem` | `InventoryApi.getInventoryById` |
| 31 | `POST` | `api/inventory` | `InventoryItem` | `InventoryItem` | `InventoryApi.createItem` |
| 32 | `PUT` | `api/inventory/{id}` | Path: `{id}`, Body: `Map<String, Any>` | `InventoryItem` | `InventoryApi.updateItem` |
| 33 | `POST` | `api/inventory/{id}/upload-image` | Path: `{id}`, Body: `{ image: "data:image/...;base64,..." }` | `InventoryItem` | `InventoryApi.uploadImage` |
| 34 | `POST` | `api/inventory/tally-sync` | None | `TallySyncResponse{ success, itemsUpdated, syncedAt, message }` | `InventoryApi.syncTally` |
| 35 | `DELETE` | `api/inventory/{id}` | Path: `{id}` | `DeleteInventoryResponse{ success, message, id, deleted }` | `InventoryApi.deleteItem` |
| 36 | `POST` | `api/inventory/import` | `ImportInventoryRequest{ items: [...] }` | `ImportInventoryResponse{ success, count, items }` | `InventoryApi.importItems` |

### 3.8 Orders & Lorry Receipt (5 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 37 | `GET` | `api/orders` | Query: `customerCode?`, `customerEmail?` | `List<OrderModel>` | `OrderApi.getOrders` / `CustomerOrderApi` |
| 38 | `GET` | `api/orders/{id}` | Path: `{id}` | `OrderModel` | `OrderApi.getOrderById` |
| 39 | `PUT` | `api/orders/{id}/status` | Path: `{id}`, Body: `{ status: "Approved" \| "Rejected" }` | `OrderModel` | `OrderApi.updateOrderStatus` |
| 40 | `PUT` | `api/orders/{id}` | Path: `{id}`, Body: LR fields map | `OrderModel` | `OrderApi.updateOrder` |
| 41 | `POST` | `api/orders` | Custom Headers + `PlaceOrderRequest` | `PlaceOrderResponse` | `PlaceOrderApi.createOrder` |

#### Special Headers for `POST api/orders`
```http
POST /api/orders HTTP/1.1
Host: api.rajputanaautomobiles.com
Authorization: Bearer <JWT_TOKEN>
Accept: application/json
X-ERP-Client-Version: 1.4.0
x-user-role: customer
x-customer-id: CUS0042
x-customer-name: Bharat%20Bearing%20Works
Content-Type: application/json
```

### 3.9 Customer Live Cart (3 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 42 | `GET` | `api/cart` | Query: `identifier` (required customer identifier) | `Response<CartApiResponse>` | `CartApi.getCart` |
| 43 | `PUT` | `api/cart` | `CartApiRequest{ customerIdentifier, customerName, items: [...] }` | `Response<CartApiResponse>` | `CartApi.saveCart` |
| 44 | `DELETE` | `api/cart` | Query: `identifier` (required customer identifier) | `Response<CartApiResponse>` | `CartApi.clearCart` |

### 3.10 System Audit Logs (1 Endpoint)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 45 | `GET` | `api/activities` | None | `List<ActivityLog>` | `ActivityApi.getActivities` |

### 3.11 Notifications Service (6 Endpoints)
| # | Method | Path | Request Body / Params | Response Body | Android Interactor |
|---|---|---|---|---|---|
| 46 | `GET` | `api/notifications` | Query: `role` (req), `customerEmail?`, `customerCode?`, `customerId?` | `Response<List<NotificationItem>>` | `NotificationApiService.getNotifications` |
| 47 | `PUT` | `api/notifications/{id}/read` | Path: `{id}` | `Response<NotificationActionResponse>` | `NotificationApiService.markAsRead` |
| 48 | `PUT` | `api/notifications/{id}/done` | Path: `{id}` | `Response<NotificationActionResponse>` | `NotificationApiService.markAsDone` |
| 49 | `PUT` | `api/notifications/read-all` | `MarkAllNotificationRequest` | `Response<List<NotificationItem>>` | `NotificationApiService.markAllAsRead` |
| 50 | `PUT` | `api/notifications/done-all` | `MarkAllNotificationRequest` | `Response<NotificationActionResponse>` | `NotificationApiService.markAllAsDone` |
| 51 | `DELETE` | `api/notifications/{id}` | Path: `{id}` | `Response<NotificationActionResponse>` | `NotificationApiService.deleteNotification` |

---

## 4. Architectural Rules & Implementation Details

1. **Repository Pattern with In-Memory TTL Caching:**
   - Repositories act as the single source of truth.
   - Cache TTLs:
     - `Inventory`: 30 seconds
     - `Dashboard Bundle`, `Orders`, `Customer Orders`, `Audit Logs`, `Detailed Ledger`: 2 minutes
     - `Staff`: 3 minutes
     - `Customers`, `Invoices`, `Ledger Summary`, `Company Profile`: 5 minutes
   - Background force-refresh is triggered by pull-to-refresh gestures.
2. **Network Timeouts:**
   - Connect timeout: 30 seconds
   - Read timeout: 60 seconds
   - Write timeout: **120 seconds** (essential for Lorry Receipt Base64 PDF uploads up to 10–14 MB).
3. **Client-Side Stock Safeguard:**
   - The backend `POST /api/orders` does not reject orders with quantities exceeding available stock.
   - The client application compares `qty` against the local inventory snapshot before placing an order.
4. **Data URI and Remote Document Handling:**
   - Documents and images can arrive as either absolute HTTPS URLs, relative paths (`/uploads/...`), or Base64 data URIs (`data:image/png;base64,...` / `data:application/pdf;base64,...`).

---
*(End of Android Reverse Engineering Specification)*
