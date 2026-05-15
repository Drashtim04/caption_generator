# Caption Generator Backend (Free Tier)

This backend is drop-in compatible with your Flutter app endpoint contract:

- `POST /api/generate-captions`
- multipart field: `image`
- response keys: `success`, `description`, `captions`, `tags`, `mood`

It uses Groq's OpenAI-compatible API with a vision model.

## 1) Create free API key

1. Go to Groq Console and create an API key.
2. Copy `backend/.env.example` to `backend/.env`.
3. Put your key in `GROQ_API_KEY`.

## 2) Run locally

```bash
cd backend
npm install
npm run dev
```

Health check:

```bash
curl http://localhost:8080/health
```

Test endpoint:

```bash
curl -X POST \
  -F "image=@../assets/images/logo111.png" \
  http://localhost:8080/api/generate-captions
```

## 3) Point Flutter app to this backend

Run Flutter with:

```bash
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

Or update your deployment URL and set `BACKEND_BASE_URL` to that host.

## 4) Deploy free (recommended: Render)

This repo already includes a Render Blueprint file at `render.yaml`.

1. Push this repo to GitHub.
2. In Render, choose **New +** -> **Blueprint**.
3. Select your repo.
4. In the service settings, add env var:
   - `GROQ_API_KEY` = your key
5. Deploy.
6. Copy your service URL (for example `https://caption-generator-backend.onrender.com`).

Use it in Flutter:

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://YOUR-SERVICE.onrender.com
```

Important for free tier:
- Free web services spin down after idle time, so the first request can be slow.

## Notes

- The backend auto-optimizes images to satisfy model request size constraints.
- If rate limits are hit, return message is forwarded to the app.
- You can switch primary model with `GROQ_MODEL` in `.env`.
- If the primary model is text-only, backend auto-retries with `GROQ_FALLBACK_VISION_MODEL`.
