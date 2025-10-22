# CloudLab Merox - Ansible Infrastructure Automation

Professional Ansible project for managing VPS/cloud instances with initial setup and configuration.

## Project Structure
```
cloudlab-merox/
├── ansible.cfg              # Ansible configuration
├── inventories/             # Inventory files
│   └── production/
│       ├── hosts           # Production inventory
│       ├── group_vars/     # Group variables
│       └── host_vars/      # Host-specific variables
├── playbooks/              # Playbook files
│   └── site.yml           # Main playbook
├── roles/                  # Custom roles
│   └── initial_setup/     # Initial VPS setup role
├── files/                  # Static files
├── templates/              # Jinja2 templates
├── requirements.yml        # Ansible Galaxy requirements
└── README.md              # This file
```

## Features

- ✅ Automatic OS detection (Debian/Ubuntu)
- ✅ System updates and upgrades
- ✅ Timezone configuration (Europe/Bucharest)
- ✅ Essential packages installation
- ✅ UFW firewall configuration
- ✅ Fail2ban installation
- ✅ Automatic security updates
- ✅ NTP time synchronization

## Requirements

- Ansible 2.16+ (with ansible-core 2.18+)
- Python 3.11+
- SSH access to target servers

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/cloudlab-merox.git
cd cloudlab-merox
```

2. Install required collections:
```bash
ansible-galaxy collection install -r requirements.yml
```

3. Configure your inventory:
```bash
# Edit inventories/production/hosts
nano inventories/production/hosts
```

## Usage

### Run full initial setup:
```bash
ansible-playbook playbooks/site.yml
```

### Run specific tags:
```bash
# Only update packages
ansible-playbook playbooks/site.yml --tags packages

# Only configure timezone
ansible-playbook playbooks/site.yml --tags timezone

# Only setup firewall
ansible-playbook playbooks/site.yml --tags firewall
```

### Dry run (check mode):
```bash
ansible-playbook playbooks/site.yml --check --diff
```

## Configuration

### Timezone
Default: `Europe/Bucharest`

Change in `roles/initial_setup/defaults/main.yml`:
```yaml
timezone: "Your/Timezone"
```

### SSH Port
Default: `22`

Change in `roles/initial_setup/defaults/main.yml`:
```yaml
allowed_ssh_port: your_port_number
```

## Security

- All sensitive data should be encrypted using Ansible Vault
- Never commit passwords or API keys to the repository
- Use SSH key authentication instead of passwords

## Tags

- `setup` - All setup tasks
- `packages` - Package installation
- `upgrade` - System upgrades
- `timezone` - Timezone configuration
- `firewall` - UFW firewall setup
- `security` - Security configurations
- `ntp` - NTP time synchronization

## License

MIT

## Author

Your Name
