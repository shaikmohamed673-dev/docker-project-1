# 3-Tier Docker Project (all files in ONE folder)

Website + API + database, deployed with Docker only.

| Tier | Tech | Container | Public? |
|---|---|---|---|
| 1 Frontend | Nginx + HTML/JS | `app-frontend` | Yes, port 8080 |
| 2 Backend | Node.js 20 + Express + pg | `app-backend` | No |
| 3 Database | PostgreSQL 16 | `app-db` | No (volume) |

## Files in this folder
```
docker-3tier-app/
├── README.md                    <- you are here
├── 01-how-docker-works.md       GUIDE: concepts and architecture
├── 02-docker-commands.md        GUIDE: every command, what and why
├── 03-dockerfile-explained.md   GUIDE: every Dockerfile / compose line
├── 04-deployment-guide.md       GUIDE: local, server, registry, backup
├── docker-compose.yml           runs all 3 tiers
├── Dockerfile.frontend          builds Tier 1 image
├── Dockerfile.backend           builds Tier 2 image (multi-stage)
├── nginx.conf                   Tier 1: web server + /api proxy
├── index.html                   Tier 1: the website
├── server.js                    Tier 2: REST API code
├── package.json                 Tier 2: Node dependencies
├── init.sql                     Tier 3: table + seed data
├── .env.example                 settings template (copy to .env)
├── .dockerignore                files excluded from image builds
├── .gitignore                   files excluded from git
└── deploy.sh                    one-command deploy
```

## Run
```bash
cp .env.example .env        # edit the password
./deploy.sh                 # or: docker compose up -d --build
```
Open http://localhost:8080

Stop: `docker compose down`  |  Delete data too: `docker compose down -v`

## Push to your repo
```bash
git init
git add .
git commit -m "3-tier Docker project"
git branch -M main
git remote add origin https://github.com/<your-user>/docker-3tier-app.git
git push -u origin main
```

## Technologies used
Docker Engine, Docker Compose v2, Nginx 1.27, HTML/CSS/JavaScript, Node.js 20, Express 4.19, pg 8.12, PostgreSQL 16, Alpine Linux, Bash, Git.

## Learning order
01 -> 02 -> run the project -> 03 -> 04
