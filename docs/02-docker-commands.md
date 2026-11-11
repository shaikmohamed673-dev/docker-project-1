# 2. Docker Commands — What and Why

## A. Images
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

## B. Containers
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

## C. Volumes
| Command | Why |
|---|---|
| `docker volume create mydata` | Create persistent storage |
| `docker volume ls` | List volumes |
| `docker volume inspect mydata` | See where it is stored |
| `docker volume rm mydata` | Delete (DATA LOST) |
| `docker volume prune` | Remove unused volumes |

Container filesystem is **temporary**. Delete the DB container without a volume = data gone.

## D. Networks
| Command | Why |
|---|---|
| `docker network create mynet` | Create private network |
| `docker network ls` | List networks |
| `docker network inspect mynet` | See connected containers/IPs |
| `docker network connect mynet web` | Attach a running container |
| `docker run --network mynet ...` | Start container on that network |

Containers on the same user-defined network reach each other by **name**.

## E. Docker Compose (multi-container) — the ones you use daily
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

## F. System / cleanup
| Command | Why |
|---|---|
| `docker version` / `docker info` | Check installation & engine details |
| `docker system df` | See disk usage |
| `docker system prune -a` | Remove all unused images/containers/networks (careful) |
| `docker login` / `docker logout` | Authenticate to registry |

## G. Debug cheat-sheet
1. Container exits immediately -> `docker logs <name>`
2. Cannot reach a service -> `docker exec -it backend sh` then `wget -qO- http://db:5432` / `ping db`
3. Wrong env var -> `docker inspect <name>` or `docker compose config`
4. Port already in use -> change `WEB_PORT` in `.env`
5. Changed code but nothing changes -> `docker compose up -d --build`
