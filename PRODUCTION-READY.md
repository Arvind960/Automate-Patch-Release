# PR-DR Automation - Production Ready

## Directory Structure

```
pr-dr/
├── config/                          # Environment configurations
│   ├── pr_vars.yml                  # PR environment variables
│   └── dr_vars.yml                  # DR environment variables
│
├── inventory/                       # Server inventory
│   ├── server_ips.yml               # Server IP addresses (PR & DR)
│   └── secure_inventory.py          # Dynamic inventory script
│
├── playbooks/                       # Ansible playbooks
│   ├── deploy_separate_vars.yml     # Main deployment playbook
│   ├── validate_separate_vars.yml   # Validation playbook
│   ├── rollback.yml                 # Rollback playbook
│   └── pre_deploy_check.yml         # Pre-deployment checks
│
├── scripts/                         # Automation scripts
│   ├── deploy_with_separate_vars.sh # Main deployment script
│   └── setup_ssh_keys.sh            # SSH key setup helper
│
├── templates/                       # Service templates
│   └── microservice.service.j2      # Systemd service template
│
├── jenkins/                         # CI/CD pipeline
│   └── Jenkinsfile-PR-to-DR         # Jenkins pipeline definition
│
├── vault/                           # Encrypted secrets
│   └── secrets.yml                  # Ansible vault (encrypt before use)
│
├── docs/                            # Documentation
│   ├── PR-DR-INSTALLATION-GUIDE.pdf # Complete installation guide
│   ├── pr_to_dr_deployment_pipeline.png # Architecture diagram
│   ├── SECURE_CONFIGURATION_GUIDE.md
│   ├── SEPARATE_VARS_GUIDE.md
│   ├── PR_TO_DR_DEPLOYMENT.md
│   └── ANSIBLE_SETUP_COMPLETE.md
│
└── README.md                        # Quick start guide
```

## Production Checklist

### Before Deployment

- [ ] Update `inventory/server_ips.yml` with actual server IPs
- [ ] Configure `config/pr_vars.yml` with PR environment details
- [ ] Configure `config/dr_vars.yml` with DR environment details
- [ ] Add credentials to `vault/secrets.yml` and encrypt it
- [ ] Setup SSH keys on all target servers
- [ ] Test connectivity to all servers
- [ ] Review and customize `templates/microservice.service.j2`

### Security

- [ ] Encrypt vault file: `ansible-vault encrypt vault/secrets.yml`
- [ ] Restrict SSH key permissions: `chmod 600 ~/.ssh/deploy_key`
- [ ] Use separate SSH keys for PR and DR (recommended)
- [ ] Enable firewall rules on target servers
- [ ] Use bastion hosts for production access

### Deployment

```bash
# Deploy to PR and DR
./scripts/deploy_with_separate_vars.sh <service-name> /path/to/artifact.jar

# Deploy to PR only
ansible-playbook playbooks/deploy_separate_vars.yml \
  -e "target_env=pr" \
  -e "service=<service-name>" \
  -e "artifact=/path/to/artifact.jar"

# Validate deployment
ansible-playbook playbooks/validate_separate_vars.yml \
  -e "target_env=pr" \
  -e "service=<service-name>"

# Rollback if needed
ansible-playbook playbooks/rollback.yml \
  -e "target_env=pr" \
  -e "service=<service-name>"
```

## Quick Start

1. Read `docs/PR-DR-INSTALLATION-GUIDE.pdf`
2. Configure your environment files
3. Add server IPs
4. Setup SSH keys
5. Test with dry run
6. Deploy!

## Support

For detailed instructions, see:
- `docs/PR-DR-INSTALLATION-GUIDE.pdf` - Complete setup guide
- `docs/SECURE_CONFIGURATION_GUIDE.md` - Security best practices
- `docs/SEPARATE_VARS_GUIDE.md` - Variable configuration guide

---

**Status:** Production Ready ✓  
**Version:** 1.0  
**Last Updated:** May 2026
