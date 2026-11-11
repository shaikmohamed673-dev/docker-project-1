# 3-Tier Docker Project

A complete, Docker-only 3-tier app to **learn Docker** and **deploy** a website + API + database.

| Tier | Tech | Container | Exposed? |
|---|---|---|---|
| 1 Presentation | Nginx + HTML | `app-frontend` | Yes, port 8080 |
| 2 Application | Node.js + Express | `app-backend` | No (internal) |
| 3 Data | PostgreSQL 16 | `app-db` | No (internal, volume) |

## Quick start
```bash
cp .env.example .env     # edit password
docker compose up -d --build
```
Open http://localhost:8080

Stop: `docker compose down`  |  Wipe data too: `docker compose down -v`

## Repo structure
```
docker-3tier-app/
├── README.md
├── docker-compose.yml          # orchestrates all 3 tiers
├── .env.example                # config template (copy to .env)
├── .gitignore
├── frontend/                   # Tier 1
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── index.html
│   └── .dockerignore
├── backend/                    # Tier 2
│   ├── Dockerfile              # multi-stage build
│   ├── package.json
│   ├── server.js
│   └── .dockerignore
├── database/                   # Tier 3
│   └── init.sql                # schema + seed data
├── scripts/
│   └── deploy.sh               # one-command deploy
└── docs/
    ├── 01-how-docker-works.md
    ├── 02-docker-commands.md
    ├── 03-dockerfile-explained.md
    └── 04-deployment-guide.md
```

## Learning path
1. `docs/01-how-docker-works.md` — concepts and architecture
2. `docs/02-docker-commands.md` — every command, what and why
3. `docs/03-dockerfile-explained.md` — every Dockerfile and compose line
4. `docs/04-deployment-guide.md` — local, server, registry, backup

## Push to your repo
```bash
cd docker-3tier-app
git init
git add .
git commit -m "Initial commit: 3-tier Docker project"
git branch -M main
git remote add origin https://github.com/<your-user>/docker-3tier-app.git
git push -u origin main
```

## Exercises
1. Change the page title in `frontend/index.html`, run `docker compose up -d --build`.
2. Add a `DELETE /api/messages/:id` endpoint in `backend/server.js`.
3. Run `docker compose exec frontend wget -qO- http://db:5432` — it fails. Why? (network isolation)
4. `docker compose down` then `up -d` — is data kept? Now try `down -v`.
5. Run `docker history` on the backend image and compare with a single-stage build.
