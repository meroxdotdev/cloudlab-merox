# CloudLab Merox - Ansible VPS Management

Modern Ansible setup pentru VPS-uri (2025 best practices).

## Quick Start (Fresh Clone)
```bash
# 1. Prerequisites
sudo apt install -y python3-pip git
pip3 install ansible

# 2. Clone & Setup
git clone <repo-url> cloudlab-merox
cd cloudlab-merox
make install

# 3. Test & Deploy
make ping          # Test connection (asks vault password)
make setup         # Full VPS setup
```

## Daily Commands
```bash
make ping          # Test connectivity
make setup         # Full setup (new VPS or recovery)
make quick         # Fast recovery
make update        # Update packages only
make check         # Dry-run (see changes without applying)
make help          # Show all commands
```

## Vault Management
```bash
# View secrets
ansible-vault view inventories/production/group_vars/all/vault.yml

# Edit secrets
ansible-vault edit inventories/production/group_vars/all/vault.yml

# Create new encrypted file
ansible-vault create path/to/secrets.yml
```

## Add New VPS
```bash
# 1. Edit inventory
nano inventories/production/hosts
# Add: vps02 ansible_host=YOUR_IP

# 2. Deploy
ansible-playbook playbooks/site.yml --limit vps02 --ask-vault-pass
```

## Advanced Usage
```bash
# Run specific tags
ansible-playbook playbooks/site.yml --tags "firewall,security" --ask-vault-pass

# Run on specific host
ansible-playbook playbooks/site.yml --limit vps01 --ask-vault-pass

# Verbose debug
ansible-playbook playbooks/site.yml -vvv --ask-vault-pass

# List tasks/tags
ansible-playbook playbooks/site.yml --list-tasks
ansible-playbook playbooks/site.yml --list-tags
```

## Troubleshooting
```bash
# Test SSH directly
ssh root@91.98.145.35

# Check inventory
ansible-inventory --graph

# Ping without vault
ansible all -i "91.98.145.35," -m ping -u root

# Syntax check
ansible-playbook playbooks/site.yml --syntax-check
```

## Project Structure
```
inventories/production/
  ├── hosts                    # Server IPs/hostnames
  └── group_vars/
      ├── all/vault.yml        # Encrypted secrets
      └── vps_servers/vars.yml # VPS variables

playbooks/
  ├── site.yml                 # Main playbook
  ├── quick-setup.yml          # Fast recovery
  └── update.yml               # Updates only

roles/
  ├── initial_setup/           # System setup
  └── tailscale_exit_node/     # Tailscale VPN
```

## Security Notes

- Always use `--ask-vault-pass` (no plaintext passwords on disk)
- Never commit `.vault_pass*` files
- Store vault password in password manager
- Prefix vault variables: `vault_api_key`, `vault_secret`, etc.

## Quick Recovery (VPS Rebuild)
```bash
# 1. Rebuild VPS via provider
# 2. Update IP in inventories/production/hosts (if changed)
# 3. Run: make quick
# Done in ~5 minutes!
```

---

**Pro Tip**: Add to `~/.bashrc` for even faster commands:
```bash
alias ap='ansible-playbook'
alias apv='ansible-playbook --ask-vault-pass'
alias aping='ansible vps_servers -m ping --ask-vault-pass'
```
