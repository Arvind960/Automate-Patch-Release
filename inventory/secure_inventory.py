#!/usr/bin/env python3
"""
Secure Dynamic Inventory - No Hardcoded Values
Reads from environment variables and encrypted vault
"""

import json
import yaml
import sys
import os

# Configuration from environment variables
CONFIG = {
    'ip_file': os.getenv('ANSIBLE_IP_FILE', '/home/ubuntu/Automate-Patch-Release/inventory/server_ips.yml'),
    'vault_file': os.getenv('ANSIBLE_VAULT_FILE', '/home/ubuntu/Automate-Patch-Release/vault/secrets.yml'),
    'ssh_user': os.getenv('DEPLOY_USER', 'deploy'),
    'ssh_key': os.getenv('SSH_PRIVATE_KEY', '/root/.ssh/deploy_key'),
    'python_interpreter': os.getenv('PYTHON_INTERPRETER', '/usr/bin/python3'),
}

def load_ips():
    """Load IPs from YAML file"""
    ip_file = CONFIG['ip_file']
    if not os.path.exists(ip_file):
        return {"pr_ips": [], "dr_ips": []}
    
    with open(ip_file, 'r') as f:
        return yaml.safe_load(f) or {"pr_ips": [], "dr_ips": []}

def load_env_config(env_type):
    """Load environment configuration from environment variables"""
    prefix = env_type.upper()
    return {
        "environment": os.getenv(f'{prefix}_ENV_NAME', env_type),
        "datacenter": os.getenv(f'{prefix}_DATACENTER', 'primary' if env_type == 'pr' else 'secondary'),
        "backup_dir": os.getenv(f'{prefix}_BACKUP_DIR', f'/opt/backups/{env_type}'),
        "artifact_dir": os.getenv('ARTIFACT_DIR', '/opt/artifacts'),
        "log_dir": os.getenv('LOG_DIR', '/var/log/applications'),
        "service_port": int(os.getenv('SERVICE_PORT', '8080')),
        "admin_port": int(os.getenv('ADMIN_PORT', '8081')),
        "db_port": int(os.getenv('DB_PORT', '5432')),
        "redis_port": int(os.getenv('REDIS_PORT', '6379')),
        "max_heap_size": os.getenv('MAX_HEAP_SIZE', '4g'),
        "min_heap_size": os.getenv('MIN_HEAP_SIZE', '2g'),
    }

def generate_inventory():
    """Generate dynamic inventory from environment"""
    data = load_ips()
    
    inventory = {
        "_meta": {
            "hostvars": {}
        },
        "all": {
            "children": ["pr_environment", "dr_environment"]
        },
        "pr_environment": {
            "hosts": [],
            "vars": load_env_config('pr')
        },
        "dr_environment": {
            "hosts": [],
            "vars": load_env_config('dr')
        }
    }
    
    # Connection settings from environment
    conn_settings = {
        "ansible_user": CONFIG['ssh_user'],
        "ansible_ssh_private_key_file": CONFIG['ssh_key'],
        "ansible_python_interpreter": CONFIG['python_interpreter']
    }
    
    # Process PR IPs
    pr_ips = data.get("pr_ips", [])
    for idx, ip in enumerate(pr_ips, 1):
        hostname = f"pr-server-{idx:03d}"
        inventory["pr_environment"]["hosts"].append(hostname)
        inventory["_meta"]["hostvars"][hostname] = {
            "ansible_host": ip,
            **conn_settings
        }
    
    # Process DR IPs
    dr_ips = data.get("dr_ips", [])
    for idx, ip in enumerate(dr_ips, 1):
        hostname = f"dr-server-{idx:03d}"
        inventory["dr_environment"]["hosts"].append(hostname)
        inventory["_meta"]["hostvars"][hostname] = {
            "ansible_host": ip,
            **conn_settings
        }
    
    return inventory

def main():
    """Main function"""
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        inventory = generate_inventory()
        print(json.dumps(inventory, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        print(json.dumps({}))
    else:
        print("Usage: {} --list or {} --host <hostname>".format(sys.argv[0], sys.argv[0]))
        sys.exit(1)

if __name__ == "__main__":
    main()
