Spendwise – App Context (for future contributors)

Latest review: repo at /Users/ashutoshtiwari/Desktop/Vibe/spendwise

Product overview
Spendwise is an entirely on-device SwiftUI expense tracker. Users register/log in locally, add or scan expenses, review spending trends, and manage monthly budgets. The UI targets both iPhone and iPad, embraces INR currency, and offers light/dark/system appearance modes.

Architecture at a glance
State containers
ExpenseStore (singleton via @StateObject in spendwiseApp): keeps expenses, receipts, monthly budgets, and merchant defaults. Persists everything to a single JSON snapshot under the app’s Documents folder; receipt images/thumbnails are stored on disk alongside the snapshot.
AuthManager (singleton): lightweight credential store backed by UserDefaults. Passwords are SHA-256 hashed before persistence. Manages current session + error messaging. No remote auth.
AppearanceSettings: user preference bridge to UserDefaults for theme, haptics flag, and “auto-save scanned receipts”.
Top-level composition
ContentView checks AuthManager.currentUser.
If nil → AuthenticationView (register/login).
Otherwise → TabView with DashboardView, ExpensesListView, CalendarRootView, SettingsView.
AddExpenseView is presented modally from tab screens to create expenses.
Data model
Expense: title, amount (Double), category (enum), date, optional notes, tax, and optional linked receiptId. Currency is always formatted as INR.
Receipt: links stored image + thumbnail paths, OCR text, parsed metadata.
MonthlyBudget: allocated amount per year-month identifier, with lastUpdated timestamp.
ExpenseCategory: nine predefined categories with SF Symbol icon mappings.
Persistence & storage
Snapshot (ExpenseStoreSnapshot): serializes arrays of expenses, receipts, budgets, and merchant defaults to a JSON file (expenses.json). Loaded on launch; seed data is provided if missing/corrupt.
Merchant defaults: dictionary keyed by normalized merchant name to the most recently used category (auto-filled for future scans/manual entries).
Receipts: ReceiptImageStore writes JPEG originals + smaller thumbnails under Documents/Receipts. Cleanup removes orphaned files when expenses/receipts delete.
Authentication data: UserDefaults keys spendwise.auth.users & spendwise.auth.currentUserEmail. Stored password hashes (SHA-256).
Preferences: AppearanceSettings toggles stored through UserDefaults.
Core flows & screens
Authentication

AuthenticationView: Register (name/email/password) or login (email/password). Validation is basic (email contains “@”, password length ≥ 6). Errors surface inline via AuthManager. Animation toggles between modes.
Dashboard (DashboardView)

Summary card: total INR spent this month, progress vs. optional monthly budget, quick stats (top category, total entries).
Category pie chart: custom CategoryPieChart using current month’s spend across up to six categories.
Recent activity: latest five expenses with navigation to detail.
Toolbar: add expense modal and (iOS) “Scan receipt” sheet.
Scanning leverages ScanReceiptViewModel, Vision OCR (ReceiptTextRecognizer), heuristic parsing (ReceiptParser), optional auto-save (bypasses manual review if OCR finds total and autoSaveScans is true).
Expense list (ExpensesListView)

Grouped by day (most recent first). Each row uses ExpenseRow.
Toolbar filters: category picker and scope (All time vs. This month). Search bar matches title/notes/category string.
Swipe-to-delete removes expenses and triggers receipt cleanup.
Calendar & budgets (CalendarRootView and CalendarView)

Monthly pager with weekday headers and per-day expense markers.
Budget summary card shows INR spent, configured budget, remaining funds, and “Edit budget” button (sheet).
Tapping a day displays detailed expenses for that date.
Budgets saved via ExpenseStore.addOrUpdateBudget(amount:month:).
Settings (SettingsView)

Shows logged-in user info + “Sign Out”.
Appearance controls: system/light/dark, auto-save scanned receipts toggle, haptics toggle (currently no in-app haptic hooks, but flag stored).
Static About info: version/build and external privacy policy link.
Expense detail & add flow

ExpenseDetailView: details + optional receipt thumbnail with full-screen preview, tax, notes, and delete action (through store).
AddExpenseView: manual entry form; amount required > 0. Returns via callback to whichever context opened it.
Receipt scanning

ScanReceiptFlowView: orchestrates VisionKit document camera (if available) or Photos picker fallback, async OCR, receipt parsing, and optional manual review (ScanReceiptReviewScreen).
ReceiptParser: extracts totals prioritizing explicit MRP/currency lines, dates in several formats, merchant heuristics, tax lines.
CategorySuggester: uses stored defaults or keyword rules to guess ExpenseCategory.
On save, DashboardView handler stores receipt (image + metadata) and creates associated expense.
Styling & theming
Color scheme obeys AppearanceSettings.
INR currency formatting is hard-coded (format: .currency(code: "INR")).
UI leans on rounded cards, gradients, SF Symbols, and SwiftUI Material backgrounds.
Testing
ReceiptParserTests: unit coverage for total, date, merchant extraction.
ScanReceiptReviewSnapshotTests: renders review screen to a bitmap (UIKit-only). Uses PNG fixture under spendwiseTests/Fixtures/receipt_sample.png.
Assets & configuration
Assets.xcassets/AppIcon.appiconset: contains the supplied logo scaled to all required sizes (filenames icon-...). Marketing 1024×1024 PNG is icon.png.
Accent color asset (AccentColor).
App icons are now fully wired to avoid “unassigned child” warnings.
Notable dependencies & OS requirements
Vision / VisionKit gating through #if canImport(...). On unsupported devices, scanning gracefully falls back to manual entry/photo picker.
No external networking libraries; entirely Foundation + SwiftUI.
Password hashing uses CryptoKit (SHA256).
Receipt storage uses UIKit for image manipulation—scanning features are iOS-only.
Known gaps / cautions for new contributors
Authentication is local-only; no encryption beyond SHA256. Treat as non-production.
Budgets, receipts, expenses stored in plain JSON/Files—no migration versioning beyond snapshot structure. Changes require careful backward compatibility.
Haptics preference unused currently; implementing feedback will need to respect flag.
Currency/regional settings fixed to INR and English text.
Auto-save scanning assumes OCR finds “MRP”/currency lines; parser rules might need refinement for other receipt formats.
No error surface for JSON persistence failures (silent catch).
Tests cover limited surface; new features should add targeted unit/UITests.
This context should equip future agents to navigate Spendwise quickly and extend features without surprises.
