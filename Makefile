.PHONY: help install ping setup quick update check facts lint traefik-setup traefik-test

help:
	@echo "Ansible VPS Management Commands"
	@echo "================================"
	@echo "install       - Install required collections"
	@echo "ping          - Test connectivity"
	@echo "setup         - Full setup (OS + Docker + Tailscale + Traefik)"
	@echo "quick         - Quick recovery setup"
	@echo "update        - Update all packages"
	@echo "check         - Dry-run setup playbook"
	@echo "facts         - Gather system facts"
	@echo "lint          - Lint all playbooks"
	@echo ""
	@echo "Infrastructure:"
	@echo "docker-setup  - Install Docker only"
	@echo "docker-test   - Test Docker installation"
	@echo "traefik-setup - Deploy Traefik reverse proxy"
	@echo "traefik-test  - Test Traefik deployment"
	@echo ""
	@echo "Utilities:"
	@echo "view-vault    - View encrypted vault file"

install:
	ansible-galaxy collection install -r requirements.yml

ping:
	ansible vps_servers -m ping --ask-vault-pass

setup:
	ansible-playbook playbooks/site.yml --ask-vault-pass

quick:
	ansible-playbook playbooks/quick-setup.yml --ask-vault-pass

update:
	ansible-playbook playbooks/update.yml --ask-vault-pass

check:
	ansible-playbook playbooks/site.yml --check --diff --ask-vault-pass

facts:
	ansible vps_servers -m setup --ask-vault-pass

lint:
	@command -v ansible-lint >/dev/null 2>&1 && ansible-lint playbooks/*.yml || echo "ansible-lint not installed. Run: pip install ansible-lint"

# Infrastructure commands
docker-setup:
	ansible-playbook playbooks/docker-setup.yml --ask-vault-pass

docker-test:
	ansible vps_servers -m shell -a "docker ps && docker compose version" --ask-vault-pass

traefik-setup:
	ansible-playbook playbooks/traefik-setup.yml --ask-vault-pass

traefik-test:
	ansible vps_servers -m shell -a "docker ps | grep traefik && docker logs traefik --tail 20" --ask-vault-pass

# View encrypted files
view-vault:
	ansible-vault view inventories/production/group_vars/all/vault.yml
