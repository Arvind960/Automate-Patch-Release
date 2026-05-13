# ✅ ANSIBLE INSTALLATION & CONFIGURATION COMPLETE

## Installation Summary
- **Ansible Version**: 2.10.8
- **Python Version**: 3.10.12
- **Installation Date**: 2026-05-08

## Directory Structure
```
/etc/ansible/
├── ansible.cfg          # Main configuration
└── hosts                # Inventory file (PR & DR environments)

/home/ubuntu/Automate-Patch-Release/
├── playbooks/
│   ├── deploy.yml       # Deployment playbook
│   ├── validate.yml     # Validation playbook
│   ├── rollback.yml     # Rollback playbook
│   └── healthcheck.yml  # Health monitoring
├── templates/
│   └── microservice.service.j2  # Systemd template
├── roles/               # Custom roles directory
├── scripts/             # Helper scripts
└── inventory/           # Additional inventories

/var/log/ansible/
└── ansible.log          # Ansible execution logs

/root/.ssh/
└── deploy_key           # SSH key for deployments
```

## Configuration Details

### Ansible Config (/etc/ansible/ansible.cfg)
- Inventory: /etc/ansible/hosts
- Log Path: /var/log/ansible/ansible.log
- Host Key Checking: Disabled
- Forks: 10 (parallel execution)
- Fact Caching: Enabled (JSON)
- Callbacks: profile_tasks, timer

### Inventory Structure (/etc/ansible/hosts)

**PR Environment (10.10.0.0/16)**
- Load Balancers: pr-lb-01, pr-lb-02
- Application Servers: pr-app-01 to pr-app-04
- Database Servers: pr-db-01, pr-db-02
- Monitoring: pr-mon-01

**DR Environment (192.168.0.0/16)**
- Load Balancers: dr-lb-01, dr-lb-02
- Application Servers: dr-app-01 to dr-app-04
- Database Servers: dr-db-01, dr-db-02
- Monitoring: dr-mon-01

## SSH Key Setup
```bash
# Public key location
/root/.ssh/deploy_key.pub

# Copy this key to all target servers:
ssh-copy-id -i /root/.ssh/deploy_key.pub deploy@<target-host>
```

## Usage Examples

### 1. Test Connectivity
```bash
# Test PR environment
ansible pr_environment -m ping

# Test DR environment
ansible dr_environment -m ping

# Test specific group
ansible pr_application -m ping
```

### 2. Deploy Microservice
```bash
# Deploy to PR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/deploy.yml \
  -e "target_env=pr" \
  -e "service=user-service" \
  -e "artifact=/opt/artifacts/user-service/20260508/user-service.jar" \
  -e "customer=customer1"

# Deploy to DR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/deploy.yml \
  -e "target_env=dr" \
  -e "service=user-service" \
  -e "artifact=/opt/artifacts/user-service/20260508/user-service.jar"
```

### 3. Validate Deployment
```bash
# Validate PR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/validate.yml \
  -e "target_env=pr" \
  -e "service=user-service"

# Validate DR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/validate.yml \
  -e "target_env=dr" \
  -e "service=user-service"
```

### 4. Rollback Deployment
```bash
# Rollback to latest backup
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/rollback.yml \
  -e "target_env=pr" \
  -e "service=user-service"

# Rollback to specific backup
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/rollback.yml \
  -e "target_env=pr" \
  -e "service=user-service" \
  -e "backup_timestamp=1715155200"
```

### 5. Health Check
```bash
# Check PR health
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/healthcheck.yml \
  -e "target_env=pr" \
  -e "service=user-service"
```

### 6. Ad-hoc Commands
```bash
# Check disk space
ansible pr_application -m shell -a "df -h"

# Check service status
ansible pr_application -m systemd -a "name=user-service state=started"

# Gather facts
ansible pr_application -m setup
```

## Next Steps

### 1. Configure Target Servers
On each target server (PR and DR), create the deploy user:
```bash
# Run on each target server
sudo useradd -m -s /bin/bash deploy
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Copy public key from Ansible controller
# Then set permissions
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys

# Grant sudo access
echo "deploy ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/deploy
```

### 2. Copy SSH Public Key to All Servers
```bash
# Display public key
cat /root/.ssh/deploy_key.pub

# Copy to each server manually or use:
for host in 10.10.2.{10..13} 192.168.2.{10..13}; do
  ssh-copy-id -i /root/.ssh/deploy_key.pub deploy@$host
done
```

### 3. Test Connectivity
```bash
# Test all hosts
ansible all -m ping

# Test specific environment
ansible pr_environment -m ping
ansible dr_environment -m ping
```

### 4. Create Required Directories on Target Servers
```bash
ansible all -m file -a "path=/opt/artifacts state=directory mode=0755"
ansible all -m file -a "path=/opt/backups state=directory mode=0755"
ansible all -m file -a "path=/var/log/applications state=directory mode=0755"
ansible all -m file -a "path=/var/log/validations state=directory mode=0755"
ansible all -m file -a "path=/var/log/rollbacks state=directory mode=0755"
```

## Playbook Features

### deploy.yml
- Creates timestamped backups
- Stops service gracefully
- Deploys new artifact
- Updates systemd service
- Starts service
- Waits for health check
- Logs deployment metadata

### validate.yml
- Service status check
- Port connectivity
- API health checks (liveness/readiness)
- Database connectivity
- Functional/smoke tests
- Log analysis (errors, OOM, connections)
- Resource utilization (CPU, memory, disk)
- Network status
- Generates comprehensive report

### rollback.yml
- Finds latest backup automatically
- Verifies backup exists
- Stops current service
- Backs up failed version
- Restores previous version
- Verifies rollback success
- Generates rollback report

## Logs & Reports

- **Ansible Logs**: /var/log/ansible/ansible.log
- **Deployment Logs**: /var/log/applications/<service>/deployment_*.log
- **Validation Reports**: /var/log/validations/<service>_*.txt
- **Rollback Logs**: /var/log/rollbacks/<service>_*.log

## Troubleshooting

### Check Ansible Configuration
```bash
ansible --version
ansible-config dump
```

### Test Inventory
```bash
ansible-inventory --list
ansible-inventory --graph
```

### Verbose Execution
```bash
ansible-playbook playbook.yml -vvv
```

### Check Logs
```bash
tail -f /var/log/ansible/ansible.log
```

## Security Recommendations

1. **SSH Key Management**
   - Rotate SSH keys regularly
   - Use different keys for different environments
   - Store keys securely (Vault, AWS Secrets Manager)

2. **Ansible Vault**
   - Encrypt sensitive variables
   ```bash
   ansible-vault create secrets.yml
   ansible-vault encrypt_string 'secret_value' --name 'variable_name'
   ```

3. **Sudo Access**
   - Limit sudo commands for deploy user
   - Use specific commands instead of ALL

4. **Network Security**
   - Restrict SSH access to Ansible controller IP
   - Use bastion/jump hosts
   - Enable firewall rules

## Support

For issues or questions:
- Check logs: /var/log/ansible/ansible.log
- Ansible documentation: https://docs.ansible.com
- Run with verbose: -vvv flag

---
**Installation Completed**: 2026-05-08 07:57 UTC
**Configured By**: Ansible Automation
**Status**: ✅ READY FOR USE
