# SOFTWARE REQUIREMENTS SPECIFICATION (SRS)

## Trading Signals Platform

---

# 1. INTRODUCTION

## 1.1 Purpose

This document provides a complete Software Requirements Specification (SRS) for the **Trading Signals Platform**, which includes:

* User application (Flutter – Web, Android, iOS)
* Admin dashboard (React)
* Backend system (FastAPI)
* Database (PostgreSQL)

This SRS serves as a blueprint for developers, designers, and stakeholders to build the system end-to-end.

---

## 1.2 Scope

The system enables:

* Users to register, deposit funds, and activate trading signals
* Automated profit calculation based on signals
* Referral and VIP systems
* Admin control over signals, users, and reports
* Real-time notifications and support chat

---

## 1.3 Definitions

| Term        | Description                                  |
| ----------- | -------------------------------------------- |
| Signal      | A predefined profit-generating configuration |
| Signal Code | A unique code to activate a signal           |
| VIP         | Special access level based on referrals      |
| Wallet      | User balance system                          |
| Referral    | User invitation system                       |

---

# 2. SYSTEM OVERVIEW

## 2.1 Architecture

* Frontend (Flutter) → User App
* Frontend (React) → Admin Dashboard
* Backend (FastAPI) → Business Logic
* Database → PostgreSQL
* Cache/Jobs → Redis + Celery

---

## 2.2 System Components

### User Application (Flutter)

* Authentication
* Dashboard
* Wallet
* Signals
* Referrals
* Market data
* Notifications
* Support chat

### Admin Dashboard (React)

* User management
* Signal management
* Reports
* Notifications
* Support chat

### Backend (FastAPI)

* REST APIs
* Business logic
* Authentication
* Background processing

---

# 3. FUNCTIONAL REQUIREMENTS

---

## 3.1 User Authentication

### Features

* Register
* Login
* Logout
* Password reset

### Requirements

* Users must provide:

  * Email
  * Password
  * Invite code (optional)

* Password must be:

  * Minimum 8 characters
  * Encrypted using bcrypt

---

## 3.2 Dashboard

### Features

* Total balance
* Active signals
* Announcement banner
* Notifications

---

## 3.3 Wallet System

### Features

* Deposit
* Withdraw
* Transaction history
* Daily performance

### Rules

* Balance = deposits + profits + bonuses - withdrawals
* Withdrawal requires withdrawal password

---

## 3.4 Signal System

### Features

* View signals
* Activate via code
* Track signal history

### Signal Activation Flow

1. User enters signal code
2. Backend validates:

   * Code exists
   * Not expired
   * Not used
3. System creates signal entry
4. Signal runs for defined duration
5. Profit added after completion

---

## 3.5 Profit Engine

### Requirements

* Runs as background job
* Calculates profit using:

Profit = balance × percentage

* Updates wallet
* Marks signal completed

---

## 3.6 Referral System

### Features

* Invite link
* Referral tracking
* Referral rewards

### Rules

* Referral becomes qualified after deposit
* Bonus given to both users

---

## 3.7 VIP System

### Qualification

* Minimum referrals
* Each referral must deposit minimum amount

### Conditions

* VIP access removed if conditions not met

---

## 3.8 Notifications

### Types

* Signal alerts
* System messages
* Announcements
* Support replies

---

## 3.9 Support Chat

### Features

* Text messages
* Image upload
* Real-time communication

---

## 3.10 Market Data

### Features

* Live prices
* Candlestick charts
* Timeframes

---

## 3.11 Admin System

### Features

* Manage users
* Create signals
* Generate signal codes
* Send notifications
* View reports
* Manage support chat

---

# 4. NON-FUNCTIONAL REQUIREMENTS

---

## 4.1 Performance

* Support 1000–2000 concurrent users
* API response time < 300ms

---

## 4.2 Scalability

* Horizontal scaling supported
* Use load balancer

---

## 4.3 Availability

* 99.9% uptime
* Auto-restart services

---

## 4.4 Usability

* Simple UI
* Responsive design
* Mobile-first approach

---

## 4.5 Maintainability

* Modular architecture
* Clean code structure
* Documentation required

---

# 5. DATABASE REQUIREMENTS

---

## Core Tables

### users

* id
* email
* password_hash
* invite_code
* referred_by
* wallet_balance
* vip_status

---

### signals

* id
* asset
* direction
* profit_percent
* duration
* status

---

### signal_codes

* id
* signal_id
* code
* expires_at
* used

---

### user_signal_entries

* id
* user_id
* signal_id
* profit
* status

---

### referrals

* id
* referrer_id
* referred_user_id
* deposit_amount

---

### notifications

* id
* user_id
* message
* type

---

### support_messages

* id
* chat_id
* message
* sender

---

# 6. API REQUIREMENTS

---

## Authentication APIs

* POST /auth/register
* POST /auth/login

---

## User APIs

* GET /dashboard
* GET /wallet
* POST /signals/activate
* GET /signals/history

---

## Admin APIs

* POST /admin/signals
* POST /admin/notifications
* GET /admin/users

---

# 7. SECURITY REQUIREMENTS

---

## 7.1 Authentication Security

* JWT-based authentication
* Token expiration
* Refresh tokens

---

## 7.2 Password Security

* bcrypt hashing
* No plain text storage

---

## 7.3 Authorization

* Role-based access control (RBAC)
* Admin vs User roles

---

## 7.4 Data Protection

* HTTPS enforced
* Sensitive data encrypted

---

## 7.5 API Security

* Rate limiting
* Input validation
* SQL injection protection

---

## 7.6 Wallet Security

* Withdrawal password
* Transaction logs
* Audit trails

---

## 7.7 Signal Security

* Code expiration
* One-time usage
* Validation checks

---

## 7.8 Admin Security

* 2FA authentication
* IP logging
* Activity logs

---

## 7.9 Logging & Monitoring

* Error logging
* Activity tracking
* Alert system

---

# 8. BACKGROUND JOBS

---

## Tasks

* Profit calculation
* VIP validation
* Signal expiration
* Notification scheduling

---

# 9. DEPLOYMENT REQUIREMENTS

---

## Infrastructure

* Docker containers
* Nginx reverse proxy
* Cloud hosting

---

## Services

* FastAPI server
* PostgreSQL
* Redis
* Celery workers

---

# 10. FUTURE ENHANCEMENTS

---

* AI-based signal generation
* Multi-level referrals
* Advanced analytics dashboard
* KYC verification
* Payment gateway integration

---

# 11. RISKS AND ASSUMPTIONS

---

## Risks

* Legal compliance issues
* Financial regulation
* Fraud prevention

---

## Assumptions

* Users have internet access
* External APIs are reliable

---

# 12. CONCLUSION

This SRS defines a complete blueprint for building a scalable and secure Trading Signals Platform with:

* Flutter (user app)
* React (admin dashboard)
* FastAPI (backend)
* PostgreSQL + Redis

This system is designed for scalability, security, and modular growth.

---
