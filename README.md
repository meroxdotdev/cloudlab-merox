# CloudLab Merox - Ansible Infrastructure Automation

Production-ready Ansible setup for Ubuntu VPS management with Docker services stack.

## Quick deploy
```bash
curl -fsSL https://merox.dev/install.sh | bash
```

## Stack Overview
- **OS**: Ubuntu 24.04 LTS hardened setup
- **Network**: Tailscale mesh VPN + exit node
- **Proxy**: Traefik with automatic HTTPS (Cloudflare DNS)
- **DNS**: Pi-hole ad-blocking DNS server
- **Management**: Portainer container orchestration
- **Dashboard**: Homepage unified dashboard
- **Monitoring**: Netdata + Beszel real-time metrics
- **Logging**: Dozzle real-time Docker logs
- **Storage**: Nextcloud private cloud + Garage S3-compatible object storage
- **Remote Access**: Apache Guacamole clientless remote desktop
- **Deployment**: ~8 minutes for full stack

## Quick Start
```bash
# Prerequisites
sudo apt install -y python3-pip git
pip3 install ansible

# Clone & Setup
git clone <repo-url> cloudlab-merox
cd cloudlab-merox
make install

# Deploy
make ping          # Test connectivity
make setup         # Full deployment (~8 min)
```

## Daily Operations
```bash
make setup            # Full deployment (new/existing VPS)
make update           # OS package updates only
make check            # Dry-run changes preview
make docker-test      # Verify Docker stack
make traefik-test     # Check Traefik status
make pihole-test      # Verify Pi-hole DNS
make portainer-test   # Check Portainer status
make netdata-test     # Check Netdata monitoring
make beszel-test      # Check Beszel monitoring
make dozzle-test      # Check Dozzle logs
make nextcloud-test   # Check Nextcloud
make garage-test      # Check Garage S3 storage
make guacamole-test   # Check Guacamole remote desktop
```

## Service Access
After deployment:
- **Homepage Dashboard**: `https://homepage.cloud.merox.dev`
- **Traefik Dashboard**: `https://traefik.cloud.merox.dev`
- **Pi-hole Admin**: `https://pihole.cloud.merox.dev/admin`
- **Portainer**: `https://portainer.cloud.merox.dev` (set admin password on first login)
- **Netdata**: `https://netdata.cloud.merox.dev`
- **Beszel**: `https://beszel.cloud.merox.dev`
- **Dozzle**: `https://dozzle.cloud.merox.dev`
- **Nextcloud**: `https://nextcloud.cloud.merox.dev` (setup admin on first login)
- **Garage WebUI**: `https://garage-ui.cloud.merox.dev`
- **Guacamole**: `https://guacamole.cloud.merox.dev` (guacadmin/guacadmin - change immediately!)

## Deployed Services

| Service | Purpose | URL | Default Credentials |
|---------|---------|-----|---------------------|
| **Traefik** | Reverse proxy & SSL | traefik.cloud.merox.dev | Vault: `traefik_dashboard_credentials` |
| **Pi-hole** | DNS ad-blocking | pihole.cloud.merox.dev | Vault: `pihole_webpassword` |
| **Portainer** | Container management | portainer.cloud.merox.dev | Set on first login |
| **Homepage** | Unified dashboard | homepage.cloud.merox.dev | No auth |
| **Netdata** | Real-time monitoring | netdata.cloud.merox.dev | No auth |
| **Beszel** | Lightweight monitoring | beszel.cloud.merox.dev | No auth |
| **Dozzle** | Docker log viewer | dozzle.cloud.merox.dev | No auth |
| **Nextcloud** | Private cloud storage | nextcloud.cloud.merox.dev | Set on first login |
| **Garage S3** | Object storage (S3) | garage.cloud.merox.dev | Generated on deploy |
| **Garage WebUI** | S3 management UI | garage-ui.cloud.merox.dev | No auth |
| **Guacamole** | Remote desktop gateway | guacamole.cloud.merox.dev | guacadmin / guacadmin |

## Vault Management
```bash
# View/Edit secrets
make view-vault
ansible-vault edit inventories/production/group_vars/all/vault.yml

# Required secrets:
# - tailscale_auth_key
# - cloudflare_api_token
# - cloudflare_email
# - traefik_dashboard_credentials (htpasswd format)
# - pihole_webpassword
# - vault_nextcloud_db_password
# - guacamole_db_password
# - garage_rpc_secret (generated with: openssl rand -hex 32)
# - garage_admin_token (generated with: openssl rand -hex 32)
```

## Add New Server
```bash
# 1. Edit inventory
nano inventories/production/hosts
# Add: vps02 ansible_host=YOUR_IP ansible_user=root

# 2. Deploy to new host only
ansible-playbook playbooks/site.yml -l vps02 --ask-vault-pass
```

## Project Structure
```
cloudlab-merox/
├── inventories/production/
│   ├── hosts                           # Server inventory
│   └── group_vars/all/vault.yml        # Encrypted secrets
├── roles/
│   ├── initial_setup/                  # OS hardening
│   ├── docker_setup/                   # Docker installation
│   ├── tailscale_exit_node/            # VPN mesh
│   ├── pihole_prereqs/                 # DNS prerequisites
│   ├── traefik_setup/                  # Reverse proxy
│   ├── pihole_setup/                   # DNS server
│   ├── portainer_setup/                # Container UI
│   ├── homepage_setup/                 # Unified dashboard
│   ├── netdata_setup/                  # System monitoring
│   ├── beszel_setup/                   # Lightweight monitoring
│   ├── dozzle_setup/                   # Log viewer
│   ├── nextcloud_setup/                # Cloud storage
│   ├── garage_setup/                   # S3-compatible storage
│   └── guacamole_setup/                # Remote desktop gateway
└── playbooks/
    ├── site.yml                        # Main playbook (all services)
    ├── traefik-setup.yml               # Traefik only
    ├── pihole-setup.yml                # Pi-hole only
    ├── portainer-setup.yml             # Portainer only
    ├── homepage-setup.yml              # Homepage only
    ├── netdata-setup.yml               # Netdata only
    ├── beszel-setup.yml                # Beszel only
    ├── dozzle-setup.yml                # Dozzle only
    ├── nextcloud-setup.yml             # Nextcloud only
    ├── garage-setup.yml                # Garage S3 only
    └── guacamole-setup.yml             # Guacamole only
```

## Garage S3 Storage

### What is Garage?
Garage is a self-hosted, S3-compatible, distributed object storage service - perfect for:
- **Kubernetes backups** (Longhorn, Velero)
- **Application object storage** (file uploads, media assets)
- **MinIO replacement** (after Docker image discontinuation)
- **Restic/Duplicity backups**

### Getting Garage Credentials
After first deployment, retrieve S3 credentials:
```bash
# SSH to server
ssh root@vps01

# Get Garage S3 credentials
docker exec garage /garage key info longhorn-key --show-secret
```

Output will show:
```
Key name: longhorn-key
Key ID: GK31c2f218a2e44f485b94239e
Secret key: 7d37d093435a41f80b7167b4eacdc28b...
```

**Save these to vault** for future reference:
```bash
ansible-vault edit inventories/production/group_vars/all/vault.yml
```

Add:
```yaml
# Garage S3 credentials (from: docker exec garage /garage key info longhorn-key --show-secret)
garage_access_key_id: "GK31c2f218a2e44f485b94239e"
garage_secret_access_key: "7d37d093435a41f80b7167b4eacdc28b..."
```


Configure Longhorn backup target:
```yaml
defaultSettings:
  backupTarget: "s3://longhorn@us-east-1/"
  backupTargetCredentialSecret: "garage-backup-secret"
```


### Garage Management
```bash
# Create new bucket
docker exec garage /garage bucket create my-bucket

# Create new access key
docker exec garage /garage key create my-app-key

# Grant permissions
docker exec garage /garage bucket allow my-bucket --read --write --key my-app-key

# View credentials
docker exec garage /garage key info my-app-key --show-secret

# List all buckets
docker exec garage /garage bucket list

# Check node status
docker exec garage /garage status
```

## Long-term Maintenance

### Monthly Tasks
```bash
# Update packages across all servers
make update

# Review and rotate secrets
ansible-vault edit inventories/production/group_vars/all/vault.yml

# Check Garage storage usage
docker exec garage /garage stats
```

### Quarterly Tasks
```bash
# Update Ansible collections
make install

# Review and update pinned versions in defaults/main.yml:
# - traefik_image: "traefik:vX.Y"
# - pihole_image: "pihole/pihole:vX.Y"
# - portainer_image: "portainer/portainer-ee:X.Y.Z"
# - nextcloud_image: "nextcloud:latest"
# - garage_image: "dxflrs/garage:vX.Y.Z"

# Test on staging/single host first
ansible-playbook playbooks/site.yml -l cloudlab1 --ask-vault-pass --check
```

### Backup Strategy
```bash
# Critical paths to backup (per host):
/srv/docker/traefik/data/acme.json      # SSL certificates
/srv/docker/pihole/etc-pihole/          # Pi-hole config + custom DNS
/srv/docker/portainer/data/             # Portainer settings
/srv/docker/homepage/config/            # Homepage dashboard config
/srv/docker/nextcloud/data/             # Nextcloud user data
/srv/docker/garage/meta/                # Garage metadata
/srv/docker/garage/data/                # Garage S3 objects
/srv/docker/guacamole/drive/            # Guacamole shared files
/srv/docker/guacamole/record/           # Guacamole session recordings

# Docker volumes to backup:
# - nextcloud_data
# - nextcloud_db_data
# - beszel_data
# - guacamole_db_data

# Garage can backup itself to another S3!
# Use Garage as backup target for other services
```

### Security Updates
```bash
# Emergency patch deployment
ansible vps_servers -m apt -a "upgrade=dist update_cache=yes" --become --ask-vault-pass

# Reboot if needed
ansible vps_servers -m reboot --become --ask-vault-pass
```

### Monitoring Checklist
- [ ] Traefik certificate renewals (auto, check logs)
- [ ] Pi-hole upstream DNS responsiveness
- [ ] Docker container health status
- [ ] Tailscale connectivity across mesh
- [ ] Disk space on `/srv/docker/` volumes
- [ ] Netdata alerts configuration
- [ ] Nextcloud cron jobs running
- [ ] Dozzle log access
- [ ] Garage storage capacity (`docker exec garage /garage stats`)
- [ ] Guacamole session recordings cleanup

### Version Pinning Philosophy
- Pin major versions only (`traefik:v3` not `traefik:v3.2.1`)
- Update quarterly with testing
- Document breaking changes in `CHANGELOG.md`

### Disaster Recovery
```bash
# VPS rebuild (same IP)
make setup

# VPS rebuild (new IP)
# 1. Update inventories/production/hosts
# 2. Update DNS A records for *.cloud.merox.dev
# 3. make setup
# 4. Restore backups to /srv/docker/
# 5. Set Portainer admin password in UI
# 6. Setup Nextcloud admin account
# 7. Change Guacamole default password (guacadmin/guacadmin)
# 8. Garage credentials auto-restore from vault
```

## Advanced Usage
```bash
# Run specific roles only
ansible-playbook playbooks/site.yml --tags storage --ask-vault-pass

# Skip specific roles
ansible-playbook playbooks/site.yml --skip-tags tailscale --ask-vault-pass

# Verbose debugging
ansible-playbook playbooks/site.yml -vvv --ask-vault-pass

# Dry-run with diff
ansible-playbook playbooks/site.yml --check --diff --ask-vault-pass

# Deploy only Garage
make garage-setup

# Deploy only Guacamole
make guacamole-setup
```

## Troubleshooting

**Port 53 conflict**
```bash
ansible vps_servers -m systemd -a "name=systemd-resolved state=stopped enabled=no" --become --ask-vault-pass
```

**Traefik certificate issues**
```bash
ansible vps_servers -m shell -a "docker logs traefik | grep -i error" --ask-vault-pass
```

**Pi-hole DNS not resolving**
```bash
# Check dnsmasq config is enabled
ansible vps_servers -m shell -a "docker exec pihole cat /etc/pihole/pihole.toml | grep etc_dnsmasq_d" --ask-vault-pass
```

**Portainer not accessible**
```bash
# Check container status
ansible vps_servers -m shell -a "docker ps | grep portainer && docker logs portainer --tail 30" --ask-vault-pass
```

**Nextcloud slow performance**
```bash
# Run occ maintenance commands
ansible vps_servers -m shell -a "docker exec -u www-data nextcloud php occ maintenance:repair" --ask-vault-pass
ansible vps_servers -m shell -a "docker exec -u www-data nextcloud php occ db:add-missing-indices" --ask-vault-pass
```

**Garage connection refused**
```bash
# Check Garage status
ansible vps_servers -m shell -a "docker logs garage --tail 50" --ask-vault-pass
ansible vps_servers -m shell -a "docker exec garage /garage status" --ask-vault-pass

# Test S3 connectivity
ansible vps_servers -m shell -a "curl -I http://localhost:3900" --ask-vault-pass
```

**Garage WebUI shows "Unknown Error"**
```bash
# Restart Garage stack
ansible vps_servers -m shell -a "cd /srv/docker/garage && docker-compose restart" --ask-vault-pass

# Check admin API
ansible vps_servers -m shell -a "netstat -tlnp | grep 3903" --ask-vault-pass
```

**Guacamole database not initialized**
```bash
# Check if init script exists
ansible vps_servers -m shell -a "ls -la /srv/docker/guacamole/init/" --ask-vault-pass

# Regenerate if missing
ansible vps_servers -m shell -a "docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > /srv/docker/guacamole/init/initdb.sql" --ask-vault-pass
```

**Docker network conflicts**
```bash
ansible vps_servers -m shell -a "docker network prune -f" --become --ask-vault-pass
```

## Use Cases

### 🏠 Homelab
- Complete self-hosted infrastructure
- Ad-blocking DNS for entire network
- Private cloud storage alternative to Google Drive/Dropbox
- Remote desktop access from anywhere
- S3 storage for backups and applications

### 🎓 Learning Platform
- Study Infrastructure as Code with Ansible
- Learn Docker networking and reverse proxies
- Practice GitOps workflows
- Understand SSL/TLS certificate management

### 💼 Small Business
- Internal file sharing with Nextcloud
- Remote access to workstations via Guacamole
- Centralized log monitoring with Dozzle
- S3-compatible storage for application backups

### ☸️ Kubernetes Support
- Garage S3 for Longhorn volume backups
- Garage S3 for Velero cluster backups
- Object storage for applications (MinIO replacement)
- Reliable backup target with active maintenance

## Contributing
1. Fork repository
2. Create feature branch: `git checkout -b feature/new-service`
3. Test on single host: `ansible-playbook playbooks/site.yml -l cloudlab1 --check`
4. Commit with conventional commits: `feat: add monitoring role`
5. Submit PR with test results

## Security Notes
- Vault password: Store in password manager, never commit
- Rotate secrets quarterly
- Use SSH keys only (no password auth)
- Fail2ban enabled by `initial_setup` role
- UFW firewall: Allow 22, 53, 80, 443, Tailscale
- Portainer: Set strong admin password on first login
- Nextcloud: Enable 2FA for admin accounts
- Guacamole: **Change default password immediately** (guacadmin/guacadmin)
- Garage: Credentials generated once, save to vault

## Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Garage Documentation](https://garagehq.deuxfleurs.fr/)
- [Guacamole Documentation](https://guacamole.apache.org/doc/gug/)
- [Nextcloud Documentation](https://docs.nextcloud.com/)

---

**Deployment Time**: 8 minutes | **Idempotent**: Yes | **Tested**: Ubuntu 24.04 LTS | **Services**: 11 deployed automatically