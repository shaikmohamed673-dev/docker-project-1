# 4. Deployment Guide

## A. Run locally (Docker only)
Requirement: Docker Desktop, or Docker Engine + Compose plugin.

```bash
git clone <your-repo-url> docker-3tier-app
cd docker-3tier-app
cp .env.example .env          # then edit the password
./deploy.sh           # or: docker compose up -d --build
```
Open http://localhost:8080 — add a message, refresh: it is stored in PostgreSQL.

Verify tiers:
```bash
docker compose ps                         # all "healthy"
curl http://localhost:8080/api/health     # frontend -> backend works
docker compose exec db psql -U appuser -d appdb -c "SELECT * FROM messages;"
```
Prove persistence:
```bash
docker compose down        # containers removed
docker compose up -d       # data is still there (volume db_data)
```

## B. Deploy to a Linux server (VPS / EC2 / Azure VM)
1. Install Docker on Ubuntu:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER      # then log out/in
```
2. Open firewall port (80 or your WEB_PORT) only. Do NOT open 5432 or 3000.
3. Get code and start:
```bash
git clone <your-repo-url> && cd docker-3tier-app
cp .env.example .env && nano .env   # strong password, WEB_PORT=80
./deploy.sh
```
4. Visit `http://<server-public-ip>`.

## C. Update after code changes
```bash
git pull
docker compose up -d --build        # rebuilds only changed layers
```

## D. Build once, deploy anywhere (registry method)
```bash
docker login
docker build -f Dockerfile.backend -t <dockerhub-user>/3tier-backend:1.0 .
docker build -f Dockerfile.frontend -t <dockerhub-user>/3tier-frontend:1.0 .
docker push <dockerhub-user>/3tier-backend:1.0
docker push <dockerhub-user>/3tier-frontend:1.0
```
On the server, in compose replace the `build:` block with
`image: <dockerhub-user>/3tier-backend:1.0` (same for frontend), then `docker compose pull && docker compose up -d`.

## E. Backup & restore the database
```bash
docker compose exec -T db pg_dump -U appuser appdb > backup.sql
cat backup.sql | docker compose exec -T db psql -U appuser -d appdb
```

## F. Production checklist
- [ ] Strong `POSTGRES_PASSWORD`, `.env` never committed
- [ ] Pinned image versions (no `latest`)
- [ ] Only the frontend port is public
- [ ] Add HTTPS (Caddy or Nginx + Let's Encrypt in front)
- [ ] Regular DB backups
- [ ] `docker compose logs` monitored / log rotation configured
- [ ] Containers run as non-root (backend already does)
