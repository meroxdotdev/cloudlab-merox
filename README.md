# cloudlab-merox — VPS Infrastructure

Production Docker stack on Oracle Cloud Free Tier (Ubuntu 24.04, ARM, 4 vCPU / 24GB RAM).
All services route through Cloudflare Tunnel — no open ports required.

## Services

| Service | URL | Purpose |
|---|---|---|
| Traefik | traefik.cloud.merox.dev | Reverse proxy + ACME certs |
| Pi-hole + Unbound | pihole.cloud.merox.dev/admin | DNS ad-blocking with DoH resolver |
| Portainer EE | 100.72.22.38:9000 (Tailscale) | Container management UI |
| Homepage | inside.merox.dev | Internal dashboard |
| Joplin Server | joplin.cloud.merox.dev | Notes sync backend |
| Uptime Kuma | status.merox.dev | Service monitoring & alerting |
| Apache Guacamole | rmt.merox.dev | Remote desktop gateway (Authentik SSO) |
| Glances | glances.cloud.merox.dev | System monitoring |
| Garage S3 | garage.cloud.merox.dev | S3-compatible object storage |
| Authentik | sso.merox.dev | Identity provider (SSO) |
| Netdata | netdata.cloud.merox.dev | Real-time performance monitoring |
| Beszel | beszel.cloud.merox.dev | Host monitoring |
| Dozzle | dozzle.cloud.merox.dev | Docker log aggregation |
| OpenClaw Dashboard | agents.cloud.merox.dev | AI agent command center |
| Code Server | code.cloud.merox.dev | Browser-based VS Code |

## First-time setup

```bash
# 1. Copy secrets file and fill in your values
cp .env.example .env
nano .env

# 2. Start Traefik first (creates the shared Docker network)
cd traefik && docker compose up -d && cd ..

# 3. Start all services
docker compose up -d

# Fix Homepage K8s widget permissions
sudo chown 1000:1000 ./config/kubeconfig.yaml
```

## Disaster recovery (automated, ~15 min)

```bash
cd cloudlab-infrastructure
make dr-full   # Terraform provision + Ansible full deploy
make restore   # Restore Joplin/Authentik DB backups
```

## Day-to-day operations

```bash
make setup             # Full idempotent deploy (all services)
make health-check      # Verify all containers are running
make update            # OS patches only
make authentik-backup  # Manual DB backup
```

## Secrets

Secrets are managed in two places:
- `.env` (gitignored) — Pi-hole, Joplin DB, code-server passwords. Copy from `.env.example`.
- `cloudlab-infrastructure/inventories/production/group_vars/all/vault.yml` (Ansible vault) — Cloudflare token, Tailscale key, Authentik, Garage.

## Networking

```
Internet → Cloudflare Tunnel → Traefik (172.25.10.2)
                                    ├── Pi-hole       (172.25.10.53)
                                    ├── Joplin        (172.25.10.61)
                                    ├── Authentik     (172.25.10.80)
                                    └── ... all on 172.25.10.0/16 network

Tailscale (100.72.22.38) → Portainer, management-only access
```
