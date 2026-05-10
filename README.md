# cloudlab-merox — Ansible + Terraform VPS Infrastructure

Production-ready infrastructure-as-code for an Ubuntu VPS running a full self-hosted Docker stack. Covers provisioning (Terraform → Hetzner), configuration (Ansible), and disaster recovery in ~15 minutes.

**Blog post:** [Oracle Cloud Free Tier: Building a Full Disaster Recovery Plan](https://merox.dev/blog/oracle-cloud-dr/)

---

## Stack

| Service | Purpose | URL |
|---|---|---|
| Traefik | Reverse proxy + Let's Encrypt | traefik.cloud.merox.dev |
| Pi-hole | DNS ad-blocking | pihole.cloud.merox.dev/admin |
| Portainer EE | Container management | portainer.cloud.merox.dev |
| Homepage | Unified dashboard | homepage.cloud.merox.dev |
| Joplin Server | Self-hosted notes (+ Postgres 15) | joplin.cloud.merox.dev |
| Uptime Kuma | Service monitoring | status.cloud.merox.dev |
| Guacamole | Remote desktop gateway | ssh.cloud.merox.dev |
| Glances | System monitoring | glances.cloud.merox.dev |
| Garage S3 | S3-compatible object storage | garage.cloud.merox.dev |
| Garage WebUI | Garage management UI | garage-ui.cloud.merox.dev |

All services go through Traefik + Cloudflare Tunnel. Admin panels are accessible only via Tailscale.

---

## Disaster Recovery (the point of this repo)

If your VPS disappears (Oracle free tier reclaimed, provider down, etc.):

```bash
# One-time setup — only needed on a new machine
make terraform-init

# Full recovery — provisions server on Hetzner + deploys everything
make dr-full
```

`dr-full` runs `terraform apply` (creates Hetzner server, updates Ansible inventory automatically), waits 45s for cloud-init, then runs `make setup`. Total time: ~15 minutes to all services running.

**What reconnects automatically:** Cloudflare Tunnel (same token), Tailscale (same auth key), Let's Encrypt certificates (regenerated via Cloudflare DNS challenge).

**What needs manual restore:** Docker volume data from your backup (Synology rsync, etc.).

---

## Setup

### Prerequisites

```bash
sudo apt install -y python3-pip git
pip3 install ansible
make install   # installs Ansible Galaxy collections
```

### Terraform (first time)

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit terraform.tfvars: add hcloud_token, ssh key path, your home IP
make terraform-init
```

Get your Hetzner API token at [console.hetzner.cloud](https://console.hetzner.cloud) → Security → API Tokens → Create Token (Read & Write).

### Ansible Vault

```bash
make vault-edit
```

Required vault variables:

```yaml
vault_tailscale_auth_key: "<reusable key from Tailscale admin panel>"
vault_joplin_db_password: "<postgres password for Joplin>"
vault_garage_rpc_secret: "<openssl rand -hex 32>"
vault_garage_admin_token: "<openssl rand -hex 32>"
# existing roles also need:
# vault_cloudflare_api_token, vault_cloudflare_email
# vault_traefik_dashboard_credentials (htpasswd format)
# vault_pihole_webpassword
```

For an existing setup migrating to DR: pull Garage secrets from the running server before it dies:
```bash
docker exec garage cat /etc/garage.toml | grep -E "rpc_secret|admin_token"
```

### Deploy

```bash
make ping     # verify connectivity
make setup    # full deploy (~12 min)
```

---

## Common Commands

```bash
# Full deploy
make setup

# Dry-run (no changes applied)
make check

# OS updates only
make update

# Individual service deploy
make traefik-setup
make pihole-setup
make portainer-setup
make joplin-setup
make uptime-kuma-setup
make guacamole-setup
make glances-setup
make garage-setup

# Terraform
make terraform-plan     # preview what will be created
make terraform-apply    # provision server, update inventory
make terraform-destroy  # tear down (with 5s warning)

# Vault
make vault-edit
make vault-show-required

# Diagnostics
make health-check
make check-resources
make traefik-test
make pihole-test
make garage-test
```

---

## Project Structure

```
cloudlab-infrastructure/
├── terraform/
│   ├── main.tf                         # Hetzner server + firewall
│   ├── variables.tf                    # hcloud_token, server_type, allowed_ips
│   ├── outputs.tf                      # server IP, ansible inventory entry
│   └── terraform.tfvars.example        # copy to terraform.tfvars (gitignored)
├── inventories/production/
│   ├── hosts                           # server IP (auto-updated by terraform-apply)
│   └── group_vars/
│       ├── all/vault.yml               # encrypted secrets (ansible-vault)
│       └── vps_servers/vars.yml        # non-sensitive vars + vault references
├── roles/
│   ├── initial_setup/                  # OS packages, timezone, NTP
│   ├── docker_setup/                   # Docker CE + compose plugin
│   ├── security_hardening/             # SSH, fail2ban, sysctl, Docker log rotation
│   ├── tailscale_exit_node/            # Tailscale VPN
│   ├── pihole_prereqs/                 # disable systemd-resolved (port 53 conflict)
│   ├── traefik_setup/                  # reverse proxy + Cloudflare ACME
│   ├── pihole_setup/                   # Pi-hole DNS
│   ├── portainer_setup/                # Portainer EE
│   ├── homepage_setup/                 # Homepage dashboard (optional kubeconfig)
│   ├── garage_setup/                   # Garage S3 storage
│   ├── joplin_setup/                   # Joplin Server + Postgres 15
│   ├── uptime_kuma_setup/              # Uptime Kuma monitoring
│   ├── guacamole_setup/                # Guacamole remote desktop
│   └── glances_setup/                  # Glances system monitoring
└── playbooks/
    ├── site.yml                        # full deploy (all roles, correct order)
    ├── quick-setup.yml                 # minimal: OS + Tailscale only
    ├── health-check.yml                # post-deploy verification
    └── update.yml                      # OS package updates
```

---

## Security Hardening

The `security_hardening` role (runs after `docker_setup`, before services) applies:

- **SSH:** password auth disabled in both `sshd_config` and `sshd_config.d/60-cloudimg-settings.conf` (Oracle Cloud override), `MaxAuthTries 3`, X11 forwarding off
- **fail2ban:** 5 attempts → 24h ban, Tailscale range excluded
- **Docker logs:** `max-size: 10m`, `max-file: 3` — prevents unbounded log growth
- **sysctl:** `vm.swappiness=10`, `vm.vfs_cache_pressure=50`
- **Disabled services:** rpcbind, ModemManager, iscsid — masked in systemd

---

## Vault Reference

All secrets are in `inventories/production/group_vars/all/vault.yml`, encrypted with Ansible Vault. Non-sensitive variables reference vault variables through `vps_servers/vars.yml`:

```yaml
# vars.yml pattern — safe to commit
tailscale_auth_key:  "{{ vault_tailscale_auth_key }}"
joplin_db_password:  "{{ vault_joplin_db_password }}"
garage_rpc_secret:   "{{ vault_garage_rpc_secret }}"
garage_admin_token:  "{{ vault_garage_admin_token }}"
```

The vault file itself never has plaintext — only encrypted blobs.

---

## Garage S3

After first deploy, retrieve S3 access credentials:

```bash
docker exec garage /garage key info longhorn-key --show-secret
```

Save `Key ID` and `Secret key` to vault. Use as Longhorn backup target:

```yaml
backupTarget: "s3://longhorn@us-east-1/"
backupTargetCredentialSecret: "garage-backup-secret"
```

---

## Troubleshooting

**Port 53 conflict (systemd-resolved)**
```bash
ansible vps_servers -m systemd -a "name=systemd-resolved state=stopped enabled=no" --become --ask-vault-pass
```

**Traefik certificate errors**
```bash
ansible vps_servers -m shell -a "docker logs traefik | grep -i error" --ask-vault-pass
```

**Garage unreachable**
```bash
ansible vps_servers -m shell -a "docker exec garage /garage status" --ask-vault-pass
```

**Docker network conflicts after rebuild**
```bash
ansible vps_servers -m shell -a "docker network prune -f" --become --ask-vault-pass
```

---

**Deployment time:** ~12 min | **DR time:** ~15 min | **Tested on:** Ubuntu 24.04 LTS ARM + x86
