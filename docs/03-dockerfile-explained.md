# 3. Dockerfiles — Every Line Explained

## Dockerfile instruction reference
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

## Backend Dockerfile (`backend/Dockerfile`) — multi-stage

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

## Frontend Dockerfile (`frontend/Dockerfile`)

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

## `.dockerignore` — why
Lists files NOT sent to the build (`node_modules`, `.git`, `.env`).
Smaller build context = faster builds, and secrets never end up inside images.

---

## docker-compose.yml — every part

```yaml
services:
```
Top-level list of containers that make up the app.

### db (Tier 3)
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

### backend (Tier 2)
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

### frontend (Tier 1)
```yaml
ports: - "${WEB_PORT:-8080}:80"
```
Publish container port 80 on host port 8080 (default if `WEB_PORT` unset). Format is `HOST:CONTAINER`.
This is the only port open to the outside.

### networks / volumes
```yaml
networks: frontend-net: backend-net:
volumes: db_data:
```
Declare them. Compose creates them automatically.
