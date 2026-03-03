# ortus_app

## Backend (Docker, server)

```bash
cd ortus-backend
cp .env.example .env
# fill real secrets in .env (JWT/CLOUDINARY). For browser clients set CORS_ORIGINS.
docker compose up -d --build
docker compose ps
```

API will be available at:

`http://<SERVER_IP>:5000/api`

## Frontend (Flutter, phone)

`ApiConfig` supports runtime override through `--dart-define`:
- if `API_BASE_URL` is not provided, app uses default `http://92.38.48.187:5000/api`

Run/build with server API:

```bash
flutter run --dart-define=API_BASE_URL=http://<SERVER_IP>:5000/api
```

or for release:

```bash
flutter build ios --release --dart-define=API_BASE_URL=http://<SERVER_IP>:5000/api
```
