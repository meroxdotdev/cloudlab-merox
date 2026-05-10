.PHONY: help install ping setup quick update check facts lint traefik-setup traefik-test pihole-setup pihole-test portainer-setup portainer-test homepage-setup homepage-test cleanup check-resources health-check terraform-init terraform-plan terraform-apply terraform-destroy dr-full vault-add-joplin

help:
	@echo "CloudLab VPS Management"
	@echo "========================"
	@echo ""
	@echo "Disaster Recovery:"
	@echo "  dr-full          - Provision Hetzner server + full Ansible deploy"
	@echo "  terraform-apply  - Provision server on Hetzner only"
	@echo "  terraform-plan   - Preview what Terraform will create"
	@echo "  terraform-init   - Initialize Terraform (first time)"
	@echo ""
	@echo "Ansible:"
	@echo "  setup            - Full deploy of all services"
	@echo "  check            - Dry-run (no changes)"
	@echo "  ping             - Test connectivity to server"
	@echo "  update           - OS package updates only"
	@echo "  health-check     - Post-deploy verification"
	@echo ""
	@echo "Individual services:"
	@echo "  traefik-setup    pihole-setup    portainer-setup"
	@echo "  homepage-setup   garage-setup    joplin-setup"
	@echo "  uptime-kuma-setup guacamole-setup glances-setup"
	@echo ""
	@echo "Vault:"
	@echo "  view-vault       - View encrypted secrets"
	@echo "  vault-add-joplin - Instructions to add Joplin DB password to vault"

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

pihole-setup:
	ansible-playbook playbooks/pihole-setup.yml --ask-vault-pass

pihole-test:
	ansible vps_servers -m shell -a "docker ps | grep pihole && dig @localhost google.com +short" --ask-vault-pass

portainer-setup:
	ansible-playbook playbooks/portainer-setup.yml --ask-vault-pass

portainer-test:
	ansible vps_servers -m shell -a "docker ps | grep portainer && curl -I http://localhost:9000" --ask-vault-pass

homepage-setup:
	ansible-playbook playbooks/homepage-setup.yml --ask-vault-pass

homepage-test:
	ansible vps_servers -m shell -a "docker ps | grep homepage && curl -I http://localhost:3000" --ask-vault-pass

netdata-setup:
	ansible-playbook playbooks/netdata-setup.yml --ask-vault-pass

netdata-test:
	ansible vps_servers -m shell -a "docker ps | grep netdata && curl -I http://localhost:19999" --ask-vault-pass

beszel-setup:
	ansible-playbook playbooks/beszel-setup.yml --ask-vault-pass

beszel-test:
	ansible vps_servers -m shell -a "docker ps | grep beszel" --ask-vault-pass

dozzle-setup:
	ansible-playbook playbooks/dozzle-setup.yml --ask-vault-pass

dozzle-test:
	ansible vps_servers -m shell -a "docker ps | grep dozzle" --ask-vault-pass

nextcloud-setup:
	ansible-playbook playbooks/nextcloud-setup.yml --ask-vault-pass

nextcloud-test:
	ansible vps_servers -m shell -a "docker ps | grep nextcloud" --ask-vault-pass

# Maintenance commands
cleanup:
	ansible-playbook playbooks/cleanup.yml --ask-vault-pass

check-resources:
	ansible-playbook playbooks/check-resources.yml --ask-vault-pass

health-check:
	ansible-playbook playbooks/health-check.yml --ask-vault-pass

# View encrypted files
view-vault:
	ansible-vault view inventories/production/group_vars/all/vault.yml

garage-setup:
	ansible-playbook playbooks/garage-setup.yml --ask-vault-pass

garage-test:
	ansible vps_servers -m shell -a "docker ps | grep -E 'garage|garage-webui' && docker exec garage /garage status" --ask-vault-pass

joplin-setup:
	ansible-playbook playbooks/site.yml --tags joplin --ask-vault-pass

joplin-test:
	ansible vps_servers -m shell -a "docker ps | grep -E 'joplin'" --ask-vault-pass

uptime-kuma-setup:
	ansible-playbook playbooks/site.yml --tags uptime-kuma --ask-vault-pass

uptime-kuma-test:
	ansible vps_servers -m shell -a "docker ps | grep uptime-kuma" --ask-vault-pass

guacamole-setup:
	ansible-playbook playbooks/site.yml --tags guacamole --ask-vault-pass

guacamole-test:
	ansible vps_servers -m shell -a "docker ps | grep guacamole" --ask-vault-pass

glances-setup:
	ansible-playbook playbooks/site.yml --tags glances --ask-vault-pass

glances-test:
	ansible vps_servers -m shell -a "docker ps | grep glances" --ask-vault-pass

# Terraform — Disaster Recovery
terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply -auto-approve
	@NEW_IP=$$(cd terraform && terraform output -raw server_ip 2>/dev/null); \
	if [ -n "$$NEW_IP" ]; then \
		sed -i "s/ansible_host=.*/ansible_host=$$NEW_IP/" inventories/production/hosts; \
		echo ""; \
		echo "Server IP: $$NEW_IP — inventory updated automatically"; \
		echo "Run: make setup  (after ~30s for cloud-init to finish)"; \
	fi

terraform-destroy:
	@echo "WARNING: This will destroy the server. Press Ctrl+C to cancel."
	@sleep 5
	cd terraform && terraform destroy

# Full Disaster Recovery — provision + configure everything
dr-full:
	@echo "Starting full disaster recovery on Hetzner..."
	$(MAKE) terraform-apply
	@echo "Waiting 45s for server boot + cloud-init..."
	@sleep 45
	$(MAKE) setup

# Vault helpers
vault-edit:
	ansible-vault edit inventories/production/group_vars/all/vault.yml

vault-show-required:
	@echo "Required vault variables (get values from running server):"
	@echo ""
	@echo "  vault_tailscale_auth_key: '<from tailscale admin panel>'"
	@echo "  vault_joplin_db_password: '<from running server docker-compose>'"
	@echo "  vault_garage_rpc_secret:  '<docker exec garage cat /etc/garage.toml>'"
	@echo "  vault_garage_admin_token: '<docker exec garage cat /etc/garage.toml>'"
	@echo ""
	@echo "Edit vault with: make vault-edit"

vault-add-joplin:
	@echo "Run: make vault-edit"
	@echo "Add line: vault_joplin_db_password: '<your-db-password>'"
