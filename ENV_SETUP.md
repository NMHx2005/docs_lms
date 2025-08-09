# ENV Setup Guide (Backend & Frontend)

Use this as the single source of truth for environment variables across dev/stage/prod.

## Backend (lms-backend)
Create a `.env` file in `lms-backend/` with:

```
NODE_ENV=development
PORT=4000

# MongoDB
MONGODB_URI=mongodb://localhost:27017/lms

# JWT Auth
JWT_SECRET=change_me_strong_secret
REFRESH_TOKEN_SECRET=change_me_another_secret
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=7d

# CORS (frontend URL)
CORS_ORIGIN=http://localhost:5173

# Third-party (optional)
CLOUDINARY_URL=
STRIPE_SECRET_KEY=
SENDGRID_API_KEY=
```

Notes:
- `JWT_SECRET`/`REFRESH_TOKEN_SECRET`: strong random strings
- `JWT_EXPIRES_IN`: e.g. 15m | 1h
- `REFRESH_TOKEN_EXPIRES_IN`: e.g. 7d | 30d
- `CORS_ORIGIN`: your FE origin(s). For multiple domains, use a comma-separated list and handle in CORS config.

## Frontend (lms-frontend)
Create a `.env` file in `lms-frontend/` with:

```
VITE_API_BASE_URL=http://localhost:4000
VITE_SOCKET_URL=http://localhost:4000
```

Notes:
- Only variables prefixed with `VITE_` are exposed to the client.
- For production, point `VITE_API_BASE_URL` to your deployed backend (`https://api.example.com`).

## Quick checklist
- [ ] Backend `.env` present and not committed
- [ ] Frontend `.env` present and not committed
- [ ] Secrets loaded (dotenv) and validated on startup
- [ ] `CORS_ORIGIN` matches the FE origin used in the browser

## Validation (recommended)
Add a runtime validator (zod/joi) to assert required envs exist and exit early with a helpful error when missing.
