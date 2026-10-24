# Dil Kaa Rista - Database Setup (PostgreSQL)

This folder contains the complete PostgreSQL database architecture for **Dil Kaa Rista**.

## Files Included

- `schema.sql`: Complete PostgreSQL DDL with tables (`users`, `profiles`, `match_requests`, `messages`), indexes, triggers, and foreign keys.
- `init.sql`: Bootstrap script with realistic Indian Matrimony seed profiles and test accounts.
- `docker-compose.yml`: Docker Compose stack for PostgreSQL 16 + pgAdmin 4.
- `db_config.env`: Environment variables and connection settings.

---

## 1. Quick Start with Docker (Recommended)

To launch PostgreSQL and pgAdmin automatically:

```bash
cd "d:\Dil Kaa Rista\database"
docker compose up -d
```

- **PostgreSQL Server**: `localhost:5432`
- **Database**: `dil_kaa_rista_db`
- **User / Password**: `postgres` / `postgres`
- **pgAdmin 4 Web GUI**: [http://localhost:5050](http://localhost:5050)
  - Login: `admin@dilkaarista.com`
  - Password: `admin123`

---

## 2. Using Local PostgreSQL Installation (psql)

If you already have PostgreSQL installed on Windows or Linux:

```bash
# 1. Create database
psql -U postgres -c "CREATE DATABASE dil_kaa_rista_db;"

# 2. Run schema
psql -U postgres -d dil_kaa_rista_db -f schema.sql

# 3. (Optional) Load seed profiles
psql -U postgres -d dil_kaa_rista_db -f init.sql
```

---

## 3. Database Schema Overview

| Table | Description |
|---|---|
| `users` | Auth credentials, email, password hash, role flags, timestamps |
| `profiles` | Matrimonial profile (full name, gender, DOB, height, religion, caste, city, education, career, photos) |
| `match_requests` | Interest sending, status (`pending`, `accepted`, `rejected`), sender & receiver |
| `messages` | Direct chat messaging between users, timestamps, read status |
