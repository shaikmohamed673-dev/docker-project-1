# 3-Tier Docker Project — Complete Guide in ONE File

Everything in this single file: what is used, how Docker works, every command, every Dockerfile line, all source code, and how to deploy.

## Table of Contents
1. What I used (technologies)
2. Project structure
3. How Docker works
4. Docker commands: what and why
5. Dockerfiles explained line by line
6. All source files (copy each into the path shown)
7. Deployment guide
8. Push to your repo

---

## 1. What I used

| Layer | Tool | Version | Why this choice |
|---|---|---|---|
| Container platform | **Docker Engine** | any recent | Builds and runs containers |
| Orchestration | **Docker Compose v2** | built into Docker | Runs all 3 tiers from one YAML file |
| Tier 1: Web server | **Nginx** | 1.27-alpine | Fast static server + reverse proxy to backend |
| Tier 1: Frontend | **HTML + CSS + vanilla JavaScript** | n/a | Simple, no build tools needed |
| Tier 2: Backend | **Node.js** | 20-alpine | Popular, small image, easy to read |
| Tier 2: API framework | **Express** | 4.19.2 | Minimal REST API framework |
| Tier 2: DB driver | **pg** (node-postgres) | 8.12.0 | Connects Node to PostgreSQL |
| Tier 3: Database | **PostgreSQL** | 16-alpine | Reliable relational database |
| Base OS in images | **Alpine Linux** | n/a | Tiny (about 5 MB), fewer security issues |
| Script | **Bash** | n/a | One-command deploy |
| Version control | **Git** | n/a | Push to GitHub/GitLab |

**Docker features used:** multi-stage build, `.dockerignore`, non-root `USER`, `HEALTHCHECK`, named volume, bind mount, two user-defined networks (tier isolation), `depends_on` with health condition, restart policy, environment variables via `.env`.

---

## 2. Project structure
```
docker-3tier-app/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── frontend/   Dockerfile, nginx.conf, index.html, .dockerignore
├── backend/    Dockerfile, server.js, package.json, .dockerignore
├── database/   init.sql
└── scripts/    deploy.sh
```

---

## 3. How Docker works (concepts)

### The problem Docker solves
"It works on my machine" — your laptop has Node 20, the server has Node 14, and the app breaks.
Docker packages your app **with everything it needs** (runtime, libraries, config) so it runs the same everywhere.

### Core ideas

| Concept | Meaning | Analogy |
|---|---|---|
| **Image** | Read-only template: OS files + runtime + your code | A recipe / class |
| **Container** | A running instance of an image (isolated process) | A cooked dish / object |
| **Dockerfile** | Text file with steps to build an image | The recipe's written steps |
| **Registry** | Server storing images (Docker Hub, GHCR) | GitHub for images |
| **Volume** | Storage that outlives a container | External hard disk |
| **Network** | Private virtual network between containers | A private LAN |
| **Docker Engine (daemon)** | Background service that builds/runs everything | The kitchen |
| **Docker CLI** | The `docker` command you type | The waiter giving orders |
| **Compose** | Runs multi-container apps from one YAML file | A full menu order |

### What happens when you type `docker run nginx`
1. CLI sends the request to the Docker daemon.
2. Daemon looks for image `nginx` locally. Not found -> pulls it from Docker Hub.
3. Daemon creates a container from the image (adds a thin writable layer on top).
4. Gives it its own network, filesystem view and process space.
5. Starts the main process (nginx).

### Containers vs Virtual Machines
- VM = full guest OS + kernel per app (GBs, slow boot).
- Container = shares the host kernel, isolated using Linux **namespaces** (what it can see)
  and **cgroups** (how much CPU/RAM it can use). MBs, starts in seconds.

### Image layers
Each Dockerfile instruction creates a **layer**. Layers are cached and shared.
If you change only `server.js`, Docker reuses all earlier layers -> fast rebuilds.
This is why we `COPY package.json` and `npm install` BEFORE copying source code.

### 3-Tier architecture in this project

```
 Browser
    |  http://localhost:8080
    v
+----------------------+   frontend-net   +----------------------+   backend-net   +----------------------+
| TIER 1: frontend     | ---------------> | TIER 2: backend      | --------------> | TIER 3: db           |
| Nginx (HTML + proxy) |                  | Node.js + Express    |                 | PostgreSQL + volume  |
| port 80 -> host 8080 |                  | port 3000 (internal) |                 | port 5432 (internal) |
+----------------------+                  +----------------------+                 +----------------------+
```

- Only the **frontend** is published to the outside world.
- The **database** is on `backend-net` only: the frontend and the internet cannot reach it. This is real tier isolation.
- Containers find each other by **service name** (`backend`, `db`) through Docker's built-in DNS.

---

## 4. Docker commands: what and why

### A. Images
| Command | What it does | Why you use it |
|---|---|---|
| `docker pull nginx:1.27-alpine` | Download an image from a registry | Get a ready-made base image |
| `docker images` | List local images | See what you have and their sizes |
| `docker build -t myapp:1.0 .` | Build an image from the Dockerfile in `.` ; `-t` = name:tag | Turn your code into an image |
| `docker build --no-cache -t myapp .` | Build ignoring cache | Force a clean build when cache gives stale results |
| `docker tag myapp:1.0 user/myapp:1.0` | Add another name to an image | Needed before pushing to a registry |
| `docker push user/myapp:1.0` | Upload image to registry | Share / deploy on other servers |
| `docker rmi myapp:1.0` | Delete an image | Free disk space |
| `docker history myapp` | Show layers and sizes | Find what makes an image big |
| `docker image prune` | Remove dangling (untagged) images | Cleanup |

### B. Containers
| Command | What it does | Why |
|---|---|---|
| `docker run nginx` | Create + start container (foreground) | Quick test |
| `docker run -d --name web -p 8080:80 nginx` | `-d` background, `--name` name it, `-p host:container` publish port | Normal way to run a service |
| `docker run -it alpine sh` | `-i` keep stdin, `-t` terminal | Interactive shell |
| `docker run --rm alpine echo hi` | Auto-delete when it exits | One-off tasks |
| `docker run -e KEY=value ...` | Set an environment variable | Pass config/secrets |
| `docker run -v mydata:/data ...` | Mount a volume | Keep data after container is deleted |
| `docker run --restart unless-stopped ...` | Restart policy | Auto-recover after crash/reboot |
| `docker ps` | List running containers | See what is alive |
| `docker ps -a` | List all including stopped | Find exited/crashed ones |
| `docker stop web` | Graceful stop (SIGTERM, then SIGKILL after 10s) | Shut down safely |
| `docker start web` | Start a stopped container | Resume |
| `docker restart web` | Stop + start | Apply config change |
| `docker rm web` | Delete a stopped container | Cleanup (`-f` forces on running) |
| `docker logs -f --tail 50 web` | Show output; `-f` follow live | **First step of debugging** |
| `docker exec -it web sh` | Run a command inside a running container | Inspect files, test connectivity |
| `docker inspect web` | Full JSON details (IP, mounts, env) | Deep debugging |
| `docker stats` | Live CPU/RAM per container | Performance check |
| `docker top web` | Processes inside container | See what is running |
| `docker cp web:/etc/nginx/nginx.conf .` | Copy files container <-> host | Grab a config/log |

### C. Volumes
| Command | Why |
|---|---|
| `docker volume create mydata` | Create persistent storage |
| `docker volume ls` | List volumes |
| `docker volume inspect mydata` | See where it is stored |
| `docker volume rm mydata` | Delete (DATA LOST) |
| `docker volume prune` | Remove unused volumes |

Container filesystem is **temporary**. Delete the DB container without a volume = data gone.

### D. Networks
| Command | Why |
|---|---|
| `docker network create mynet` | Create private network |
| `docker network ls` | List networks |
| `docker network inspect mynet` | See connected containers/IPs |
| `docker network connect mynet web` | Attach a running container |
| `docker run --network mynet ...` | Start container on that network |

Containers on the same user-defined network reach each other by **name**.

### E. Docker Compose (multi-container) — the ones you use daily
| Command | What / Why |
|---|---|
| `docker compose up -d` | Create networks/volumes + start all services in background |
| `docker compose up -d --build` | Rebuild images first, then start (after code changes) |
| `docker compose ps` | Status + health of services |
| `docker compose logs -f backend` | Follow one service's logs |
| `docker compose exec db psql -U appuser -d appdb` | Open SQL shell inside DB |
| `docker compose exec backend sh` | Shell inside backend |
| `docker compose stop` | Stop, keep containers |
| `docker compose down` | Stop + remove containers and networks (**volumes kept**) |
| `docker compose down -v` | Also delete volumes (**DB data lost**) |
| `docker compose build` | Build only |
| `docker compose config` | Validate YAML and show final config with .env applied |
| `docker compose pull` | Pull newest images |
| `docker compose restart backend` | Restart one service |

### F. System / cleanup
| Command | Why |
|---|---|
| `docker version` / `docker info` | Check installation & engine details |
| `docker system df` | See disk usage |
| `docker system prune -a` | Remove all unused images/containers/networks (careful) |
| `docker login` / `docker logout` | Authenticate to registry |

### G. Debug cheat-sheet
1. Container exits immediately -> `docker logs <name>`
2. Cannot reach a service -> `docker exec -it backend sh` then `wget -qO- http://db:5432` / `ping db`
3. Wrong env var -> `docker inspect <name>` or `docker compose config`
4. Port already in use -> change `WEB_PORT` in `.env`
5. Changed code but nothing changes -> `docker compose up -d --build`

---

## 5. Dockerfiles explained line by line

### Dockerfile instruction reference
| Instruction | Purpose |
|---|---|
| `FROM` | Base image to start from. Every Dockerfile starts here |
| `WORKDIR` | Set working directory (creates it). Later commands run here |
| `COPY` | Copy files from your machine into the image |
| `ADD` | Like COPY + extract tar / download URL (prefer COPY) |
| `RUN` | Execute a command **at build time** (install packages). Creates a layer |
| `ENV` | Set an environment variable (build + runtime) |
| `ARG` | Variable available only at build time |
| `EXPOSE` | Documents the port the app listens on (does NOT publish it) |
| `USER` | Run following commands/process as this user (not root) |
| `HEALTHCHECK` | Command Docker runs periodically to test if app is healthy |
| `CMD` | Default command when container **starts** (can be overridden) |
| `ENTRYPOINT` | Fixed executable; CMD becomes its arguments |
| `VOLUME` | Declares a mount point for persistent data |

`RUN` = build time. `CMD` = run time. This is the most common confusion.

---

### Backend Dockerfile (`backend/Dockerfile`) — multi-stage

```dockerfile
FROM node:20-alpine AS deps
```
Start from the official Node 20 image on Alpine Linux (about 5 MB base, small and secure).
`AS deps` names this stage so we can copy from it later.

```dockerfile
WORKDIR /app
```
Create `/app` inside the image and `cd` into it. All next commands run there.

```dockerfile
COPY package.json ./
```
Copy ONLY package.json first. Docker caches this layer; if dependencies didn't change,
the slow `npm install` below is skipped on rebuilds.

```dockerfile
RUN npm install --omit=dev
```
Install production dependencies only (skips devDependencies) -> smaller image.

```dockerfile
FROM node:20-alpine
```
Start a **second, fresh stage**. Everything from stage 1 is discarded unless we copy it.
Result: the final image has no build leftovers or npm cache.

```dockerfile
WORKDIR /app
```
Same working directory in the final image.

```dockerfile
ENV NODE_ENV=production
```
Tells Express and libraries to run in optimized production mode.

```dockerfile
COPY --from=deps /app/node_modules ./node_modules
```
Copy the installed modules from stage `deps` into this final image.

```dockerfile
COPY server.js ./
```
Copy the app source LAST, because it changes most often (keeps earlier layers cached).

```dockerfile
USER node
```
Run as the unprivileged `node` user. If the app is hacked, the attacker is not root.

```dockerfile
EXPOSE 3000
```
Documentation: this app listens on 3000. Other containers can reach it on that port in the network.

```dockerfile
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1
```
Every 15s call `/api/health`. 3s timeout. Ignore failures for the first 10s (startup).
After 3 failures the container is marked `unhealthy`. `|| exit 1` makes failure return a non-zero code.

```dockerfile
CMD ["node", "server.js"]
```
Command executed when the container starts. JSON (exec) form runs node directly as PID 1,
so it receives stop signals properly.

---

### Frontend Dockerfile (`frontend/Dockerfile`)

```dockerfile
FROM nginx:1.27-alpine
```
Base: Nginx web server on Alpine. Version is pinned (never rely on `latest` in production).

```dockerfile
COPY nginx.conf /etc/nginx/conf.d/default.conf
```
Replace the default site config with ours (serves the page and proxies `/api/` to `backend:3000`).

```dockerfile
COPY index.html /usr/share/nginx/html/index.html
```
Put our website in Nginx's default web root.

```dockerfile
EXPOSE 80
```
Nginx listens on 80 inside the container (host mapping is done by `ports:` in compose).

```dockerfile
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1
```
Checks the homepage loads.

(No `CMD` needed: the nginx base image already defines one that starts nginx.)

---

### `.dockerignore` — why
Lists files NOT sent to the build (`node_modules`, `.git`, `.env`).
Smaller build context = faster builds, and secrets never end up inside images.

---

### docker-compose.yml — every part

```yaml
services:
```
Top-level list of containers that make up the app.

#### db (Tier 3)
```yaml
image: postgres:16-alpine
```
Use the ready-made Postgres image (no Dockerfile needed).
```yaml
container_name: app-db
restart: unless-stopped
```
Fixed name. Restart automatically on crash or server reboot unless you stopped it manually.
```yaml
environment:
  POSTGRES_USER: ${POSTGRES_USER}
  ...
```
Postgres creates this user/password/database on first start. `${...}` is read from your `.env` file.
```yaml
volumes:
  - db_data:/var/lib/postgresql/data
```
Named volume holds the DB files -> data survives `docker compose down`.
```yaml
  - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
```
Bind-mount our SQL script. Postgres runs every file in that folder **once** on first init. `:ro` = read-only.
```yaml
networks: [backend-net]
```
Only the backend tier can talk to the DB.
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ... -d ..."]
```
`pg_isready` tells whether Postgres accepts connections. Used so the backend waits for a *ready* DB, not just a *started* one.

#### backend (Tier 2)
```yaml
build: ./backend
```
Build the image from `backend/Dockerfile`.
```yaml
environment: DB_HOST: db ...
```
`db` is the service name; Docker DNS resolves it to the DB container's IP.
```yaml
depends_on:
  db:
    condition: service_healthy
```
Start backend only after DB healthcheck passes.
```yaml
networks: [frontend-net, backend-net]
```
Backend is in both networks: it is the bridge between the tiers.

#### frontend (Tier 1)
```yaml
ports: - "${WEB_PORT:-8080}:80"
```
Publish container port 80 on host port 8080 (default if `WEB_PORT` unset). Format is `HOST:CONTAINER`.
This is the only port open to the outside.

#### networks / volumes
```yaml
networks: frontend-net: backend-net:
volumes: db_data:
```
Declare them. Compose creates them automatically.

---

## 6. All source files

Create each file at the path shown in its heading.

### `docker-compose.yml`

```yaml
services:

  # ===== Tier 3: Database =====
  db:
    image: postgres:16-alpine
    container_name: app-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - db_data:/var/lib/postgresql/data                         # persistent data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks: [backend-net]                                      # NOT reachable from frontend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 10

  # ===== Tier 2: Backend API =====
  backend:
    build: ./backend
    container_name: app-backend
    restart: unless-stopped
    environment:
      DB_HOST: db
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    depends_on:
      db:
        condition: service_healthy                               # wait until DB is ready
    networks: [frontend-net, backend-net]                        # bridge between tiers

  # ===== Tier 1: Frontend (website) =====
  frontend:
    build: ./frontend
    container_name: app-frontend
    restart: unless-stopped
    ports:
      - "${WEB_PORT:-8080}:80"                                   # only public entry point
    depends_on:
      - backend
    networks: [frontend-net]

networks:
  frontend-net:
  backend-net:

volumes:
  db_data:
```

### `.env.example`

```bash
# Copy to .env  ->  cp .env.example .env   (never commit .env)
POSTGRES_USER=appuser
POSTGRES_PASSWORD=change_me_strong_password
POSTGRES_DB=appdb
WEB_PORT=8080
```

### `.gitignore`

```text
.env
node_modules/
*.log
.DS_Store
```

### `frontend/Dockerfile`

```dockerfile
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1
```

### `frontend/nginx.conf`

```nginx
server {
    listen 80;

    # Serve the website
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    # Forward API calls to the backend container (Docker DNS name "backend")
    location /api/ {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### `frontend/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>3-Tier Docker App</title>
<style>
 body{font-family:system-ui,sans-serif;max-width:560px;margin:40px auto;padding:0 16px}
 input{padding:8px;width:65%} button{padding:8px 14px}
 li{padding:6px 0;border-bottom:1px solid #ddd}
</style>
</head>
<body>
<h1>3-Tier Docker App</h1>
<p>Frontend (Nginx) &rarr; Backend (Node) &rarr; Database (PostgreSQL)</p>
<input id="t" placeholder="Write a message..."> <button onclick="add()">Save</button>
<ul id="list"></ul>
<script>
async function load(){
  const r = await fetch('/api/messages'); const d = await r.json();
  document.getElementById('list').innerHTML =
    d.map(m => '<li>'+m.text.replace(/</g,'&lt;')+'</li>').join('');
}
async function add(){
  const t = document.getElementById('t');
  await fetch('/api/messages',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({text:t.value})});
  t.value=''; load();
}
load();
</script>
</body>
</html>
```

### `frontend/.dockerignore`

```text
.git
*.md
```

### `backend/Dockerfile`

```dockerfile
# ---------- Stage 1: install dependencies ----------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

# ---------- Stage 2: small runtime image ----------
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1
CMD ["node", "server.js"]
```

### `backend/package.json`

```json
{
  "name": "backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": { "express": "4.19.2", "pg": "8.12.0" }
}
```

### `backend/server.js`

```javascript
const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

// Settings come from environment variables (set in docker-compose.yml)
const pool = new Pool({
  host: process.env.DB_HOST,       // "db" = service name; Docker DNS resolves it
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
  port: 5432,
});

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/api/messages', async (_req, res) => {
  try {
    const r = await pool.query('SELECT * FROM messages ORDER BY id DESC LIMIT 20');
    res.json(r.rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/messages', async (req, res) => {
  const text = (req.body.text || '').trim();
  if (!text) return res.status(400).json({ error: 'text required' });
  try {
    const r = await pool.query('INSERT INTO messages(text) VALUES($1) RETURNING *', [text]);
    res.status(201).json(r.rows[0]);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.listen(3000, () => console.log('Backend listening on :3000'));
```

### `backend/.dockerignore`

```text
node_modules
npm-debug.log
.git
.env
```

### `database/init.sql`

```sql
-- Runs ONCE, only when the data volume is empty (first start)
CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
INSERT INTO messages (text) VALUES ('Hello from PostgreSQL (Tier 3)!');
```

### `scripts/deploy.sh`

```bash
#!/usr/bin/env bash
# One-command deploy:  ./scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

command -v docker >/dev/null || { echo "Docker not installed"; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 missing"; exit 1; }

if [ ! -f .env ]; then
  cp .env.example .env
  echo ">> .env created from template. EDIT the password, then run again."
  exit 1
fi

PORT=$(grep -E '^WEB_PORT=' .env | cut -d= -f2)
PORT=${PORT:-8080}

echo ">> Building images..."
docker compose build

echo ">> Starting containers..."
docker compose up -d

echo ">> Waiting for services..."
for i in $(seq 1 30); do
  if curl -fs "http://localhost:${PORT}/api/health" >/dev/null 2>&1; then
    echo ">> App is UP at http://localhost:${PORT}"; docker compose ps; exit 0
  fi
  sleep 2
done
echo ">> Not healthy in time. Logs:"; docker compose logs --tail=50; exit 1
```


---

## 7. Deployment guide

### A. Run locally (Docker only)
Requirement: Docker Desktop, or Docker Engine + Compose plugin.

```bash
git clone <your-repo-url> docker-3tier-app
cd docker-3tier-app
cp .env.example .env          # then edit the password
./scripts/deploy.sh           # or: docker compose up -d --build
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

### B. Deploy to a Linux server (VPS / EC2 / Azure VM)
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
./scripts/deploy.sh
```
4. Visit `http://<server-public-ip>`.

### C. Update after code changes
```bash
git pull
docker compose up -d --build        # rebuilds only changed layers
```

### D. Build once, deploy anywhere (registry method)
```bash
docker login
docker build -t <dockerhub-user>/3tier-backend:1.0 ./backend
docker build -t <dockerhub-user>/3tier-frontend:1.0 ./frontend
docker push <dockerhub-user>/3tier-backend:1.0
docker push <dockerhub-user>/3tier-frontend:1.0
```
On the server, in compose replace `build: ./backend` with
`image: <dockerhub-user>/3tier-backend:1.0` (same for frontend), then `docker compose pull && docker compose up -d`.

### E. Backup & restore the database
```bash
docker compose exec -T db pg_dump -U appuser appdb > backup.sql
cat backup.sql | docker compose exec -T db psql -U appuser -d appdb
```

### F. Production checklist
- [ ] Strong `POSTGRES_PASSWORD`, `.env` never committed
- [ ] Pinned image versions (no `latest`)
- [ ] Only the frontend port is public
- [ ] Add HTTPS (Caddy or Nginx + Let's Encrypt in front)
- [ ] Regular DB backups
- [ ] `docker compose logs` monitored / log rotation configured
- [ ] Containers run as non-root (backend already does)

---

## 8. Push to your repo
```bash
cd docker-3tier-app
chmod +x scripts/deploy.sh
git init
git add .
git commit -m "Initial commit: 3-tier Docker project"
git branch -M main
git remote add origin https://github.com/<your-user>/docker-3tier-app.git
git push -u origin main
```

## Exercises
1. Change the page title in `frontend/index.html`, then `docker compose up -d --build`.
2. Add `DELETE /api/messages/:id` in `backend/server.js`.
3. Run `docker compose exec frontend wget -qO- http://db:5432`. It fails. Why? (network isolation)
4. `docker compose down` then `up -d`: data kept. Now try `down -v`.
5. Run `docker history` on the backend image and compare with a single-stage build.
