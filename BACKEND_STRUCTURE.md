# Backend Structure Overview

FastAPI backend with PostgreSQL database, Redis caching, and Celery workers for background tasks. Modular architecture with separate services for authentication, user management, wallet operations, signal handling, referrals, notifications, support, and admin functionalities. JWT-based authentication with role-based access control (RBAC) for users and admins.


# 1️⃣ Backend Architecture (FastAPI)

```text
Client Apps
Flutter (User) + React (Admin)

        │
        ▼

FastAPI Backend
--------------------------------
Auth Module
User Module
Wallet Module
Signal Module
Referral Module
VIP Module
Notification Module
Support Module
Admin Module

        │
        ▼
PostgreSQL

        │
        ▼
Redis + Celery Workers
```

---

# 2️⃣ Project Structure (Production Ready)

```text
backend/

app/

 ├── main.py
 ├── core/
 │     config.py
 │     security.py
 │     database.py
 │     dependencies.py
 │
 ├── models/
 │     user.py
 │     signal.py
 │     wallet.py
 │     referral.py
 │     notification.py
 │
 ├── schemas/
 │     auth_schema.py
 │     user_schema.py
 │     signal_schema.py
 │
 ├── services/
 │     auth_service.py
 │     wallet_service.py
 │     signal_service.py
 │     referral_service.py
 │
 ├── routes/
 │
 │     ├── auth_routes.py
 │     ├── user_routes.py
 │     ├── wallet_routes.py
 │     ├── signal_routes.py
 │     ├── referral_routes.py
 │     ├── notification_routes.py
 │     ├── support_routes.py
 │
 │     └── admin/
 │           users_admin.py
 │           signals_admin.py
 │           reports_admin.py
 │
 ├── workers/
 │     profit_worker.py
 │     vip_worker.py
 │
 └── utils/
       helpers.py
```

---

# 3️⃣ Database Design (PostgreSQL)

## 🔹 users

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  password_hash TEXT,
  invite_code VARCHAR(50),
  referred_by INT,
  wallet_balance NUMERIC DEFAULT 0,
  vip_level INT DEFAULT 0,
  withdrawal_password_hash TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 signals

```sql
CREATE TABLE signals (
  id SERIAL PRIMARY KEY,
  asset VARCHAR(20),
  direction VARCHAR(10),
  profit_percent FLOAT,
  duration_hours INT,
  status VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 signal_codes

```sql
CREATE TABLE signal_codes (
  id SERIAL PRIMARY KEY,
  signal_id INT,
  code VARCHAR(50) UNIQUE,
  expires_at TIMESTAMP,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 user_signal_entries

```sql
CREATE TABLE user_signal_entries (
  id SERIAL PRIMARY KEY,
  user_id INT,
  signal_id INT,
  entry_balance NUMERIC,
  participation_amount NUMERIC,
  profit_percent FLOAT,
  status VARCHAR(20),
  started_at TIMESTAMP,
  ends_at TIMESTAMP
);
```

---

## 🔹 wallet_transactions

```sql
CREATE TABLE wallet_transactions (
  id SERIAL PRIMARY KEY,
  user_id INT,
  type VARCHAR(50),
  amount NUMERIC,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 deposits

```sql
CREATE TABLE deposits (
  id SERIAL PRIMARY KEY,
  user_id INT,
  amount NUMERIC,
  status VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 withdrawals

```sql
CREATE TABLE withdrawals (
  id SERIAL PRIMARY KEY,
  user_id INT,
  amount NUMERIC,
  status VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 referrals

```sql
CREATE TABLE referrals (
  id SERIAL PRIMARY KEY,
  referrer_id INT,
  referred_user_id INT,
  deposit_amount NUMERIC,
  status VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 notifications

```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id INT,
  title TEXT,
  message TEXT,
  type VARCHAR(20),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔹 announcements

```sql
CREATE TABLE announcements (
  id SERIAL PRIMARY KEY,
  title TEXT,
  message TEXT,
  start_date TIMESTAMP,
  end_date TIMESTAMP
);
```

---

## 🔹 support_messages

```sql
CREATE TABLE support_messages (
  id SERIAL PRIMARY KEY,
  user_id INT,
  sender_type VARCHAR(10),
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

# 4️⃣ Authentication Flow

## 🔐 JWT-Based Auth

### Login Flow

```text
User → /auth/login
      ↓
Verify password
      ↓
Generate JWT
      ↓
Return token
```

### Token Structure

```json
{
  "user_id": 10,
  "role": "user",
  "exp": 123456789
}
```

---

## Middleware

Every request:

```text
Authorization: Bearer <token>
```

FastAPI dependency:

```python
def get_current_user():
    # decode JWT
    # return user
```

---

# 5️⃣ API Structure (Complete)

---

# 🔹 AUTH ROUTES

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/auth/me
POST /api/v1/auth/change-password
```

---

# 🔹 USER ROUTES

```text
GET /api/v1/users/profile
PUT /api/v1/users/update
```

---

# 🔹 DASHBOARD

```text
GET /api/v1/dashboard
```

Returns:

```json
{
  "balance": 500,
  "active_signals": 2,
  "vip_level": 1,
  "announcements": []
}
```

---

# 🔹 WALLET ROUTES

```text
GET  /api/v1/wallet
GET  /api/v1/wallet/transactions
POST /api/v1/wallet/withdraw
GET  /api/v1/wallet/deposits
```

---

# 🔹 SIGNAL ROUTES

```text
GET  /api/v1/signals
POST /api/v1/signals/activate
GET  /api/v1/signals/history
```

---

## Signal Activation API

```text
POST /signals/activate
```

### Request

```json
{
  "signal_code": "BTC7X91"
}
```

### Logic

```text
1. Validate code
2. Check expiry
3. Check not used
4. Fetch signal
5. Calculate participation
6. Create user_signal_entry
7. Mark code used
```

---

# 🔹 REFERRAL ROUTES

```text
GET /api/v1/referrals
GET /api/v1/referrals/stats
```

---

# 🔹 NOTIFICATION ROUTES

```text
GET /api/v1/notifications
PUT /api/v1/notifications/read
```

---

# 🔹 SUPPORT ROUTES

```text
GET  /api/v1/support/messages
POST /api/v1/support/message
```

---

# 🔹 ADMIN ROUTES

## USERS

```text
GET /api/v1/admin/users
PUT /api/v1/admin/users/{id}
```

---

## SIGNALS

```text
POST /api/v1/admin/signals
PUT  /api/v1/admin/signals/{id}
DELETE /api/v1/admin/signals/{id}
POST /api/v1/admin/signals/{id}/generate-code
```

---

## NOTIFICATIONS

```text
POST /api/v1/admin/notifications
```

---

## REPORTS

```text
GET /api/v1/admin/reports
```

---

# 6️⃣ Signal Engine Logic

### Activation

```text
User → enters code
      ↓
Validate
      ↓
Create entry
```

---

### Profit Worker (Celery)

```python
for signal in active_signals:
    if now >= signal.ends_at:
        profit = signal.entry_balance * percent
        update wallet
        mark completed
```

---

# 7️⃣ Background Jobs

## Celery Tasks

```text
profit calculation (every minute)
VIP validation (daily)
signal expiration (hourly)
notifications scheduler
```

---

# 8️⃣ Security Layer

---

## Authentication

```text
JWT + refresh tokens
```

---

## Authorization

```text
RBAC:
user
admin
```

---

## API Security

```text
rate limiting
input validation
SQL injection prevention
```

---

## Wallet Security

```text
withdrawal password
transaction logs
```

---

## Admin Security

```text
2FA (recommended)
IP tracking
audit logs
```

---

# 9️⃣ Example Endpoint (FastAPI)

```python
@router.post("/signals/activate")
def activate_signal(data: ActivateSignalSchema, user=Depends(get_current_user)):
    
    code = get_signal_code(data.signal_code)

    if not code or code.used:
        raise HTTPException(400, "Invalid code")

    if code.expires_at < now():
        raise HTTPException(400, "Expired")

    signal = get_signal(code.signal_id)

    entry = create_user_signal_entry(user, signal)

    mark_code_used(code)

    return {"message": "Activated"}
```

---

# 🔟 Scaling Strategy

```text
Add Redis caching
Add load balancer
Split services later
```