# 💰 Actual Track — Local-First Expense & Budget Tracker

<p align="center">
  <img src="assets/app_icon.jpg" width="120" alt="Actual Track Logo" />
</p>

<p align="center">
  <strong>Privacy-First • Zero-Based Budgeting • AI-Powered Insights</strong>
</p>

<p align="center">
  <a href="#-download">
    <img src="https://img.shields.io/badge/Download-Windows-059669?style=for-the-badge&logo=windows&logoColor=white" alt="Download for Windows" />
  </a>
  <img src="https://img.shields.io/badge/version-1.0.0-2563EB?style=for-the-badge" alt="Version 1.0.0" />
  <img src="https://img.shields.io/badge/Flutter-3.35+-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/License-MIT-7C3AED?style=for-the-badge" alt="MIT License" />
</p>

---

A modern, privacy-first personal finance application inspired by **Actual Budget**, built with **Flutter** for **Desktop (Windows / macOS / Linux)**, **Mobile (Android / iOS)**, and **Web**.

Features the luxury **"Snow & Emerald" White Theme**, zero-based envelope budgeting, interactive cashflow trends, multi-account liquidity management, AI-powered financial advisor, and an offline-first SQLite database.

## 🌐 Website

📥 **[Visit the Landing Page & Download](https://your-github-username.github.io/actual-track/)** — View the demo, explore features, and download the app.

---

## ✨ Key Features

### 1. 📊 Zero-Based Envelope Budgeting
- "Give every dollar a job" allocation model
- Real-time **Free to Budget** balance calculation
- Visual progress meters with on-track / over-budget alerts

### 2. 📱 Responsive Adaptive Experience
- **Desktop (≥ 900px)**: Permanent collapsible sidebar, 4-metric KPI banner, multi-column layout
- **Mobile (< 900px)**: Bottom navigation dock, stacked cards, floating action button for 1-tap logging

### 3. 🔒 Local-First SQLite Engine
- Cross-platform SQLite via `sqflite` (mobile) + `sqflite_common_ffi` (desktop)
- Zero network latency, instant search & filtering
- **Your data never leaves your device**

### 4. 📈 Spending Analytics & Visuals
- Smooth cash flow spline area chart (Income vs. Expense trajectories)
- Interactive category distribution donut chart
- Proportional outflow rankings

### 5. 🏦 Multi-Account Liquidity Management
- Checking, High-Yield Savings, Investment Vault, Credit, and Cash wallets
- Automatic balance reconciliation on transaction logging/deletion

### 6. 🤖 AI Financial Advisor (Gemini-Powered)
- In-app chat with Gemini AI models (3.8 Flash, 2.5 Flash/Pro, 2.0 Flash, 1.5 Flash/Pro)
- Voice input via speech-to-text
- Text-to-speech responses
- Context-aware financial advice based on your spending patterns
- OpenUI generative widgets for rich in-chat visualizations

### 7. 📅 Financial Calendar & Schedules
- Recurring bill tracking
- Payday forecasts
- Monthly ledger dates
- Visual calendar with transaction overlays

### 8. ⚙️ Settings & Customization
- API key configuration for Gemini
- Model selection across 6+ Gemini variants
- Voice settings (TTS engine, speed, pitch)
- Data import/export
- Database management

---

## 🖼️ App Preview

<table>
  <tr>
    <td align="center"><strong>Dashboard</strong></td>
    <td align="center"><strong>Budget Envelopes</strong></td>
  </tr>
  <tr>
    <td>KPI cards, account carousel, cash flow chart, and envelope overview</td>
    <td>Zero-based budgeting with visual progress bars</td>
  </tr>
  <tr>
    <td align="center"><strong>Analytics</strong></td>
    <td align="center"><strong>AI Advisor</strong></td>
  </tr>
  <tr>
    <td>Donut chart & ranked category spending breakdown</td>
    <td>Gemini-powered chat with voice support</td>
  </tr>
</table>

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── openui/         # OpenUI generative widget system for AI chat
│   ├── services/       # Gemini AI Service, Voice Service (TTS/STT)
│   ├── theme/          # AppColors ("Snow & Emerald"), Typography, ThemeData
│   └── utils/          # Currency & Date Formatters
├── data/
│   ├── local/          # SQLite DbHelper (FFI + Mobile), Sample Seed Data
│   ├── models/         # Account, Category Envelope, Schedule, Transaction models
│   └── repositories/   # SQLite CRUD & Atomic Transaction management
├── providers/
│   ├── app_provider.dart        # Financial state, KPI derivations, envelope math
│   └── navigation_provider.dart # Responsive navigation & sidebar toggle state
└── presentation/
    ├── screens/
    │   ├── dashboard_screen.dart     # Overview KPIs, accounts, cashflow chart
    │   ├── envelopes_screen.dart     # Zero-based category allocation
    │   ├── accounts_screen.dart      # Liquidity breakdown & account creator
    │   ├── transactions_screen.dart  # Searchable & filterable ledger
    │   ├── analytics_screen.dart     # Donut chart & category outflow
    │   ├── calendar_screen.dart      # Financial calendar & schedules
    │   ├── ai_advisor_screen.dart    # Gemini AI chat interface
    │   └── settings_screen.dart      # App configuration
    └── widgets/
        ├── responsive_scaffold.dart     # Adaptive Desktop/Mobile layout
        ├── metric_card.dart             # KPI stat cards
        ├── envelope_card.dart           # Budget progress bars
        ├── account_card.dart            # Account liquidity pills
        ├── transaction_tile.dart        # Transaction entries
        ├── month_selector_bar.dart      # Month navigation
        ├── add_transaction_modal.dart   # New transaction form
        ├── edit_transaction_modal.dart  # Edit transaction form
        ├── add_category_modal.dart      # New envelope form
        ├── add_schedule_modal.dart      # New schedule form
        ├── edit_budget_dialog.dart      # Budget adjustment
        └── reconcile_account_modal.dart # Account reconciliation
```

**Dependencies:**
| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `sqflite` / `sqflite_common_ffi` | SQLite persistence |
| `fl_chart` | Interactive charts |
| `google_fonts` | Typography |
| `intl` | Date/currency formatting |
| `uuid` | Unique ID generation |
| `http` | Gemini API calls |
| `flutter_tts` | Text-to-speech |
| `speech_to_text` | Voice input |
| `flutter_markdown` | Rich AI responses |
| `path_provider` | Platform-safe file paths |

---

## 📥 Download

### Windows
| Type | File | Size |
|------|------|------|
| **Installer** (recommended) | [ActualTrackSetup.exe](dist/ActualTrackSetup.exe) | ~14.5 MB |
| **Portable** (no install) | [ActualTrack-Windows-Portable.zip](dist/ActualTrack-Windows-Portable.zip) | ~14.4 MB |

### Build from Source

#### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.35+ recommended)

#### 1. Install Dependencies
```bash
flutter pub get
```

#### 2. Run on Desktop (Windows)
```bash
flutter run -d windows
```

#### 3. Run on Mobile (Android / iOS)
```bash
flutter run -d chrome  # or connected device / emulator
```

#### 4. Build Release Executable
```bash
flutter build windows
```

---

## 🤖 AI Advisor Setup

To use the AI Financial Advisor feature:

1. Get a free API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Open the app → Settings → paste your Gemini API key
3. Select your preferred model (Gemini 3.8 Flash recommended)
4. Start chatting with your AI financial advisor!

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

<p align="center">
  Made with ❤️ and Flutter
</p>
