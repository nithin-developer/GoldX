I am designing this as a **professional fintech-style app**, with emphasis on:

* clarity
* trust
* speed
* premium feel
* low clutter
* strong hierarchy
* mobile-first but web-friendly

---

# 1. Product UI Direction for GoldX

**GoldX** should feel like a:

* premium trading dashboard
* clean investment product
* fast and data-driven application
* secure and trustworthy platform

The design should avoid looking like a casual app. It should feel closer to:

* a finance dashboard
* a broker app
* a modern crypto signal platform

The core visual style should be:

* **dark mode first**
* high contrast
* glassy cards
* minimal gradients
* strong spacing
* readable numbers
* sharp data presentation

---

# 2. Visual Identity

## App Name

**GoldX**

## Design Personality

* professional
* premium
* trustworthy
* fast
* analytical
* modern

## Style Keywords for Stitch

Use these words in your design prompts:

**“modern fintech dashboard, dark theme, premium cards, clean hierarchy, glowing accent, minimal layout, data-rich, mobile-first, professional trading app, crisp typography, subtle motion”**

---

# 3. Best Color Palette

For a trading/signals app, the best palette is a **dark neutral base with one primary accent** and controlled success/error colors.

## Primary Palette

### Background

* Main background: `#0B1220`
* Secondary background: `#111B2E`
* Surface/card background: `#162133`

### Text

* Primary text: `#F5F7FB`
* Secondary text: `#A7B0C0`
* Muted text: `#6D7788`

### Accent Colors

* Primary accent: `#4F8CFF`
* Secondary accent: `#00D4A6`

### Positive / Negative

* Success / profit: `#22C55E`
* Loss / warning: `#EF4444`

### Divider / Border

* Border color: `#243149`

## Why this palette works

* Dark background gives a premium trading feel
* Blue accent gives trust and tech energy
* Green is naturally associated with profits
* Very dark surfaces make cards stand out
* Numbers and charts become easier to read

## Recommended usage ratio

* 70% dark neutrals
* 20% surfaces/cards
* 10% accent colors

---

# 4. Typography System

Use a clean geometric sans-serif style.

## Best font choice

### Option 1: **Inter**

Best for:

* dashboards
* numbers
* clean UI
* readable on web and mobile

### Option 2: **Poppins**

Best for:

* slightly more modern and friendly appearance

## Recommended choice for GoldX

**Inter**

Why:

* looks professional
* works well for financial data
* readable at small sizes
* excellent for web and mobile

## Font hierarchy

* App title: 24–28 px, bold
* Section title: 18–20 px, semi-bold
* Card title: 14–16 px, semi-bold
* Body text: 13–15 px, regular
* Micro labels: 11–12 px, medium

## Numeric styling

Use tabular or aligned numbers for:

* balance
* profit
* percentages
* timestamps

This makes the app feel much more professional.

---

# 5. Layout Principles

## Core layout rule

Every screen should follow:

* top header
* main content section
* bottom navigation
* consistent horizontal padding
* card-based grouping

## Spacing system

Use an 8px spacing system:

* 8
* 16
* 24
* 32

## Grid

* Mobile: single-column cards
* Web/tablet: 2-column or 3-column dashboard grid

## Card style

* 16–20 px border radius
* subtle shadow
* 1px border
* slightly lighter background than page
* compact but spacious

---

# 6. Navigation Structure

For GoldX, the best MVP navigation is a **bottom navigation bar** with 5 main tabs.

## Bottom Nav Tabs

1. **Home**
2. **Signals**
3. **Market**
4. **Referrals**
5. **Profile**

This is the most intuitive structure for users.

### Why this works

* Home gives overview
* Signals is the core feature
* Market adds live context
* Referrals supports growth
* Profile contains account actions

---

# 7. Header Design

## Header structure

The header should be minimal and functional.

### Left side

* app logo or GoldX wordmark
* optional small greeting text

### Right side

* notification icon
* profile avatar button

## Home header content

* “Good Evening, Nithin”
* small subtitle like “Your account overview”

## Signals page header

* page title
* filter icon
* search icon or info icon

## Style

Use a sticky header on web and a compact app bar on mobile.

---

# 8. Core Pages for MVP

For a professional MVP, these pages are enough:

1. Splash screen
2. Welcome / onboarding
3. Login
4. Register
5. Forgot password
6. Home dashboard
7. Signals list
8. Signal detail / activate signal
9. Follow signal code page
10. Market page
11. Referrals page
12. Notifications page
13. Profile page
14. Deposit history
15. Withdraw history
16. Support chat
17. Settings
18. Withdrawal password setup

That is a solid MVP scope.

---

# 9. Page-by-Page UI Guide

## 9.1 Splash Screen

A very short branded screen.

### Elements

* GoldX logo
* small animated pulse or chart line
* loading indicator

### Mood

* premium
* fast
* simple

---

## 9.2 Welcome Screen

This should explain the product quickly.

### Elements

* headline: “Trade Smarter with GoldX”
* subtitle: “Track signals, monitor market movement, and manage your account in one place.”
* buttons:

  * Login
  * Create Account

### UI style

* one hero illustration
* dark gradient background
* clean CTA buttons

---

## 9.3 Login Screen

Minimal and focused.

### Fields

* Email
* Password

### Elements

* forgot password link
* login button
* register link

### Design behavior

* show password toggle
* inline validation
* error messages below fields

---

## 9.4 Register Screen

Should be clean and trustworthy.

### Fields

* Email
* Password
* Confirm password
* Invite code

### Notes

Invite code should look optional if your business logic allows that.

### Extras

* password strength indicator
* terms checkbox
* create account button

---

## 9.5 Home Dashboard

This is the most important screen.

### Content blocks

1. **Top balance card**
2. **Announcement ticker**
3. **Quick action buttons**
4. **Daily profit card**
5. **Active signal summary**
6. **Recent activity**
7. **Market snapshot**

### Balance card

Display:

* total balance
* today’s profit
* growth indicator

### Quick actions

* Deposit
* Withdraw
* Follow Signal
* Support

### Dashboard feel

It should feel like a finance cockpit.

---

## 9.6 Signals Page

This is the business-critical page.

### Layout

* list of signal cards
* filter chips
* search by asset
* VIP section at top if user qualifies

### Signal card content

* asset name
* direction up/down
* participation %
* duration
* status
* activate button

### Card states

* active
* expired
* locked
* VIP only

### Visual pattern

Use strong icons:

* green arrow up
* red arrow down
* timer icon
* lock icon for restricted signals

---

## 9.7 Follow Signal Page

This page should be highly focused.

### Fields

* signal code input
* activate signal button

### Behavior

After paste:

* validate code
* show loading
* success state or expired state

### Output states

* success: “Signal Activated Successfully”
* expired: “Signal Expired”
* invalid: “Invalid Code”

### Good UI detail

Use a scan/paste icon inside the input field.

---

## 9.8 Market Page

This page should look more analytical.

### Components

* top market selector
* live price tiles
* candlestick chart
* timeframe chips
* change percentage
* volume section

### Supported pairs

* BTC/USDT
* ETH/USDT
* BNB/USDT
* SOL/USDT
* XRP/USDT

### Recommended layout

* first row: current price and change
* second row: chart
* third row: timeframe selectors
* fourth row: watchlist

---

## 9.9 Referrals Page

Should look growth-oriented.

### Components

* invite code block
* invite link copy card
* referral stats cards
* VIP progress tracker
* referral list

### Important UI detail

Show progress toward next VIP level using a clean progress bar.

Example:

* 7/10 referrals completed
* 3 more needed for VIP1

---

## 9.10 Notifications Page

Should be clean and grouped.

### Sections

* Signal alerts
* System notifications
* Support replies
* Announcements

### Design

Use stacked notification cards with:

* icon
* title
* message
* timestamp
* read/unread state

---

## 9.11 Profile Page

This should contain account management.

### Sections

* user info
* wallet settings
* password change
* withdrawal password
* security settings
* logout

### Design

Use grouped settings cards, not long lists.

---

## 9.12 Support Chat

This must feel fast and responsive.

### Components

* chat bubbles
* message input
* image upload
* send button
* support status indicator

### Design

* user messages aligned right
* support messages aligned left
* support message color should be slightly different

---

# 10. Component System

For GoldX, create reusable UI components.

## Core components

* BalanceCard
* SignalCard
* MarketCard
* ReferralStatsCard
* NotificationTile
* PrimaryButton
* SecondaryButton
* InputField
* BottomNavBar
* HeaderBar
* SectionTitle
* StatusBadge
* ProgressBar
* EmptyStateCard

---

# 11. Button Design

## Primary button

* solid blue fill
* white text
* 14–16px radius
* full width on mobile

## Secondary button

* transparent or outlined
* border in accent color

## Destructive button

* red outline or red fill for logout / delete actions

---

# 12. Form Design

Forms should be compact and clean.

### Rules

* label above field
* placeholder inside field
* validation text below field
* one primary CTA at the bottom

### Best practice

Do not overload the user with too many fields on one screen.

---

# 13. Animations and Motion

Use subtle motion, not flashy effects.

## Good animations

* fade in on page load
* slide transition between pages
* card hover on web
* count-up animation for balance
* shimmer loader
* progress bar animation
* toast notification slide up
* bottom sheet animate from bottom

## Avoid

* excessive bounce
* overused neon glow
* heavy parallax
* too many moving elements

### Animation feel

* smooth
* premium
* responsive
* soft easing

---

# 14. Loading States

GoldX needs polished loading UI.

## Use

* skeleton cards
* shimmer placeholders
* circular loaders for button actions
* progress indicators for signal activation

This is especially important for:

* dashboard
* market data
* signal activation
* notifications

---

# 15. Empty States

Every empty page should show a helpful message.

Example:

* no signals available
* no transactions yet
* no notifications yet
* no referrals yet

### Empty state design

* icon
* heading
* short explanation
* action button

---

# 16. Error States

Error screens should be user-friendly.

Examples:

* invalid signal code
* expired signal
* network unavailable
* session expired
* insufficient balance

### Design

Use:

* red icon
* short title
* explanation
* retry button

---

# 17. Responsive Design Rules

Since GoldX will run on web and mobile:

## Mobile

* single column layout
* bottom nav visible
* compact cards

## Tablet

* two-column dashboard
* more space for charts

## Web

* sidebar can replace bottom nav if you want a more desktop-like feel
* dashboard can expand into 2–3 columns

For Flutter web, you can use a responsive breakpoint system.

---

# 18. Recommended App Structure in Flutter UI

For UI organization, use this structure:

* Authentication flow
* Main shell layout
* Bottom navigation scaffold
* Individual feature screens
* Shared widget library

This makes your app easy to scale.

---

# 19. Best Navigation Pattern for GoldX

For a polished MVP, use:

## Mobile

* bottom nav
* top app bar
* floating action only if needed

## Web

* left sidebar on desktop
* bottom nav on mobile web

This gives you a good responsive experience across platforms.

---

# 20. Best Design Prompt for Google Stitch

Use this as your **master prompt** in Google Stitch:

```text
Design a professional fintech mobile and web app called GoldX. The app should have a premium dark theme with a clean, modern, data-driven interface. Use a dark navy background, glass-like cards, blue primary accents, green success states, red warning states, and crisp typography like Inter. The layout should be mobile-first but responsive for web. Include a top header with logo, notifications, and profile avatar. Use a bottom navigation bar with Home, Signals, Market, Referrals, and Profile. The Home dashboard should show total balance, profit summary, announcement banner, quick actions, market snapshot, and recent activity. The Signals page should show signal cards with asset, direction, participation, duration, and activate button. Include a Follow Signal screen with signal code input and success/error states. The Market page should show live asset prices and candlestick chart sections. The Referrals page should show invite code, invite link, referral stats, and VIP progress. The Profile page should include account settings, withdrawal password, security settings, and logout. Use smooth subtle animations, rounded cards, clean spacing, clear hierarchy, skeleton loaders, and a premium trading dashboard feel.
```

---

# 21. Best UI Generation Prompt per Screen

You can also generate each screen separately.

## Home screen prompt

```text
Create a premium dark fintech dashboard for GoldX. Show a top balance card, daily profit summary, announcement ticker, quick action buttons, market snapshot cards, and recent activity. Use glassmorphism cards, blue primary accents, green profit indicators, and smooth rounded corners. Make it mobile-first and clean.
```

## Signals page prompt

```text
Create a signal listing screen for GoldX with premium dark UI. Show signal cards with asset name, direction icon, participation rate, duration, status badge, and activate button. Include filter chips, search input, and VIP-only lock states. Use clean spacing and strong visual hierarchy.
```

## Follow signal prompt

```text
Create a minimal follow-signal screen for GoldX. Include a signal code input field, paste icon, activate button, and clear success/error states. Use a dark modern finance app style with subtle motion and premium card layout.
```

## Market page prompt

```text
Create a live market screen for GoldX. Show asset selector chips, live price tiles, candlestick chart area, timeframe selectors, and change percentage indicators. Use a dark analytical dashboard style with clean borders and polished spacing.
```

## Referrals prompt

```text
Create a referral dashboard for GoldX with invite code, copy invite link card, referral stats cards, VIP progress bar, and referral list. Use a premium fintech style with dark background, blue accents, and clean modular cards.
```

## Profile prompt

```text
Create a profile/settings screen for GoldX. Show account info, password change, withdrawal password setup, security options, and logout. Use a clean dark settings layout with grouped cards and subtle icons.
```

---

# 22. Final UI Direction Summary

For GoldX, the best design choice is:

* **Dark theme**
* **Inter font**
* **Bottom navigation**
* **Top app bar with profile and notifications**
* **Glass-like cards**
* **Blue + green accent palette**
* **Minimal but premium motion**
* **Dashboard-first layout**
* **Financial data hierarchy**
* **Strong mobile and web responsiveness**

This will make the app feel modern, trustworthy, and product-ready.
