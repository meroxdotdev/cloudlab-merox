.PHONY: help install ping setup update check lint facts

help:
	@echo "Ansible VPS Management Commands"
	@echo "================================"
	@echo "install     - Install required collections"
	@echo "ping        - Test connectivity"
	@echo "setup       - Run full initial setup"
	@echo "quick       - Quick recovery setup"
	@echo "update      - Update all packages"
	@echo "check       - Dry-run setup playbook"
	@echo "facts       - Gather system facts"
	@echo "lint        - Lint all playbooks"

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

# Quick commands without vault (for testing)
ping-no-vault:
	ansible all -i "91.98.145.35," -m ping -u root -e ansible_python_interpreter=/usr/bin/python3

# View encrypted files
view-vault:
	ansible-vault view inventories/production/group_vars/all/vault.yml
