# Dil Kaa Rista - Django Backend

Django REST Framework backend for the **Dil Kaa Rista** matrimony platform, configured with PostgreSQL database support, Token Authentication, opposite-gender matching, photo uploads, match requests, and real-time chat APIs.

---

## Architecture & Apps

- `accounts/`: Custom User model (`accounts.User`), Token Authentication, Registration (`/api/auth/register/`), Login (`/api/auth/login/`), Logout (`/api/auth/logout/`), Current User (`/api/auth/me/`).
- `profiles/`: Detailed matrimony profile model (`Profile`), Profile viewing, editing (`/api/profiles/me/`), and photo upload (`/api/profiles/upload-photo/`).
- `matches/`: Smart matchmaking feed (`/api/matches/`) with strict opposite gender matching, age filters, religion, caste, state, and city filtering. Match requests / interests (`/api/matches/send-interest/`, `/api/matches/requests/`, `/api/matches/requests/<id>/respond/`).
- `chat/`: Direct messaging between users (`/api/chat/messages/`, `/api/chat/send/`).
- `core/`: Management command `seed_data` to bootstrap the database with sample profiles and admin user.

---

## Setup & Running

### 1. Create and Activate Virtual Environment

```bash
cd "d:\Dil Kaa Rista\backend"
python -m venv venv

# Windows
.\venv\Scripts\activate

# Linux / Mac
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Database

Check `.env` file for your PostgreSQL credentials:

```ini
DB_ENGINE=postgresql
DB_NAME=dil_kaa_rista_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=127.0.0.1
DB_PORT=5432
```

*(Note: You can set `USE_SQLITE=True` in `.env` if you want to test without a running PostgreSQL server).*

### 4. Run Migrations

```bash
python manage.py makemigrations accounts profiles matches chat core
python manage.py migrate
```

### 5. Seed Database with Realistic Profiles

```bash
python manage.py seed_data
```

This will automatically create:
- **Admin**: `admin@dilkaarista.com` / `Admin@123`
- **8 Pre-built Profiles**: (Priya Sharma, Aarav Patel, Ananya Iyer, Rohan Verma, Sneha Gupta, Kabir Kapoor, Diya Singh, Vikram Reddy) with photos and bio.

### 6. Start the Server

```bash
python manage.py runserver 0.0.0.0:8000
```

- API Root: [http://127.0.0.1:8000/api/](http://127.0.0.1:8000/api/)
- Django Admin: [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/)
