# Admin Dashboard — Full Implementation Plan

Build a fully functional admin dashboard for the Trading Signals Platform by extending the existing **MUI Minimal Kit** (React + Vite + TypeScript + MUI 7) template. All pages integrate with the FastAPI backend via `axios` and `@tanstack/react-query`.

## User Review Required

> [!IMPORTANT]
> **Backend API Base URL** — The plan uses `http://localhost:8000/api/v1` as the default. Please confirm the correct base URL.

> [!IMPORTANT]
> **Removing template pages** — The existing `blog`, `products` pages are template demos. This plan removes them from routes & nav. Confirm this is OK.

---

## Proposed Changes

### Dependencies

Install: `axios`, `@tanstack/react-query`, `react-hot-toast`

---

### API Service Layer

#### [NEW] [api.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/api.ts)
- Axios instance with `baseURL`, auto-attach JWT from `localStorage`
- Response interceptor: 401 → redirect to `/sign-in`

#### [NEW] [auth.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/auth.service.ts)
- `login(email, password)` → POST `/auth/login`
- `logout()` → clear token

#### [NEW] [user.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/user.service.ts)
- `getUsers()`, `updateUser(id, data)`

#### [NEW] [signal.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/signal.service.ts)
- `getSignals()`, `createSignal()`, `deleteSignal()`, `generateCode(signalId)`

#### [NEW] [referral.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/referral.service.ts)
- `getReferrals()`, `getVipUsers()`

#### [NEW] [notification.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/notification.service.ts)
- `sendNotification()`, `createAnnouncement()`

#### [NEW] [support.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/support.service.ts)
- `getChats()`, `replyToChat()`

#### [NEW] [report.service.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/services/report.service.ts)
- `getReports()`

---

### Auth Context & Guard

#### [NEW] [auth-context.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/context/auth-context.tsx)
- Context with `user`, `token`, `login`, `logout`
- Persist token in `localStorage`, check role === "admin"

#### [NEW] [auth-guard.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/context/auth-guard.tsx)
- Wraps dashboard routes — redirects to `/sign-in` if not authenticated

---

### App & Config Updates

#### [MODIFY] [config-global.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/config-global.ts)
- Add `apiUrl` to config

#### [MODIFY] [app.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/app.tsx)
- Remove GitHub FAB
- Wrap with `AuthProvider` and `QueryClientProvider`

#### [MODIFY] [main.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/main.tsx)
- No structural change, providers are in [app.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/app.tsx)

---

### Navigation & Routing

#### [MODIFY] [nav-config-dashboard.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/layouts/nav-config-dashboard.tsx)
Nav items: Dashboard, Users, Signals, Referrals, VIP, Notifications, Announcements, Support, Reports. Uses `Iconify` icons instead of SVGs (more icons available).

#### [MODIFY] [sections.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/routes/sections.tsx)
- Remove `BlogPage`, `ProductsPage`
- Add lazy-loaded pages: `SignalsPage`, `ReferralsPage`, `VipUsersPage`, `NotificationsPage`, `AnnouncementsPage`, `SupportPage`, `ReportsPage`
- Wrap dashboard routes in `AuthGuard`

---

### Pages (one file each in `src/pages/`)

#### [NEW] [signals.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/signals.tsx)
#### [NEW] [referrals.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/referrals.tsx)
#### [NEW] [vip-users.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/vip-users.tsx)
#### [NEW] [notifications.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/notifications.tsx)
#### [NEW] [announcements.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/announcements.tsx)
#### [NEW] [support.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/support.tsx)
#### [NEW] [reports.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/reports.tsx)
#### [DELETE] [blog.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/blog.tsx)
#### [DELETE] [products.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/pages/products.tsx)

---

### Sections (view logic per feature)

Each section follows the existing pattern: folder in `src/sections/` with a [view/](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/sections/overview/view/overview-analytics-view.tsx#19-157) subfolder and an [index.ts](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/_mock/index.ts) barrel.

#### Dashboard — [MODIFY] `src/sections/overview/`
- Rewrite [overview-analytics-view.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/sections/overview/view/overview-analytics-view.tsx) with API-driven KPI cards (Total Users, Deposits, Active Signals, VIP Users, Daily Profit)
- Keep [AnalyticsWidgetSummary](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/sections/overview/analytics-widget-summary.tsx#32-143) and `AnalyticsWebsiteVisits` chart components
- Remove mock data references, use `react-query` hooks

#### Users — [MODIFY] `src/sections/user/`
- Rewrite [user-view.tsx](file:///d:/Nithin/Freelance/Projects/Germany%20Projects/TradingSignals/admin-app/src/sections/user/view/user-view.tsx) to fetch from `GET /admin/users`
- Update table columns: Email, Balance, VIP Level, Status
- Add Block/Unblock toggle action
- Remove mock data

#### Signals — [NEW] `src/sections/signals/`
- `signals-view.tsx` — table + "Create Signal" form in modal
- `signal-table-row.tsx` — row with asset, profit%, duration, status, actions (generate code, delete)
- `signal-code-modal.tsx` — modal showing generated code + copy button

#### Referrals — [NEW] `src/sections/referrals/`
- `referrals-view.tsx` — table: Referrer, Referred User, Deposit, Status

#### VIP — [NEW] `src/sections/vip/`
- `vip-view.tsx` — table: User, VIP Level, Referrals Count

#### Notifications — [NEW] `src/sections/notifications/`
- `notifications-view.tsx` — form (title, message, target dropdown) + send button

#### Announcements — [NEW] `src/sections/announcements/`
- `announcements-view.tsx` — form (title, content, duration) + list of active announcements

#### Support — [NEW] `src/sections/support/`
- `support-view.tsx` — split pane: chat list (left) + chat messages (right) + reply input

#### Reports — [NEW] `src/sections/reports/`
- `reports-view.tsx` — date range filter + charts (revenue, deposits, withdrawals, profit)

#### Cleanup
- [DELETE] `src/sections/blog/` (template demo)
- [DELETE] `src/sections/product/` (template demo)

---

## Verification Plan

### Automated Build Check
```bash
cd "d:\Nithin\Freelance\Projects\Germany Projects\TradingSignals\admin-app"
npm run build
```
Must compile with zero TypeScript errors.

### Browser Verification
1. Run `npm run dev` and open in browser
2. Verify `/sign-in` page loads → login form visible
3. Sign in → redirects to `/` (dashboard)
4. Check sidebar nav has all items: Dashboard, Users, Signals, Referrals, VIP, Notifications, Announcements, Support, Reports
5. Click each nav item → correct page renders with proper layout
6. Verify dashboard shows KPI cards and charts
7. Verify users page shows data table with block/unblock
8. Verify signals page shows table + create form
9. Verify support page shows chat UI

### Manual Verification (by user)
- Connect to a running FastAPI backend and confirm API responses populate the pages
- Test login with admin credentials
- Test signal code generation end-to-end
