# ============================================
# PR AND DR SEPARATE VARIABLE FILES
# ============================================

## FILE STRUCTURE

```
/home/ubuntu/Automate-Patch-Release/config/
├── pr_vars.yml          ← PR environment variables
└── dr_vars.yml          ← DR environment variables

/home/ubuntu/Automate-Patch-Release/playbooks/
├── deploy_separate_vars.yml      ← Uses pr_vars.yml or dr_vars.yml
└── validate_separate_vars.yml    ← Uses pr_vars.yml or dr_vars.yml
```

## HOW IT WORKS

### Automatic Variable Loading
```yaml
# In playbook:
vars_files:
  - "{{ playbook_dir }}/../config/{{ target_env }}_vars.yml"

# When target_env=pr → loads pr_vars.yml
# When target_env=dr → loads dr_vars.yml
```

## EDIT VARIABLES

### PR Variables
```bash
vi /home/ubuntu/Automate-Patch-Release/config/pr_vars.yml

# Edit:
- pr_database.host: "pr-db-master.company.local"
- pr_ports.service_port: 8080
- pr_jvm.max_heap: "8g"
- pr_paths.backup_dir: "/opt/backups/pr"
```

### DR Variables
```bash
vi /home/ubuntu/Automate-Patch-Release/config/dr_vars.yml

# Edit:
- dr_database.host: "dr-db-master.company.local"
- dr_ports.service_port: 8080
- dr_jvm.max_heap: "8g"
- dr_paths.backup_dir: "/opt/backups/dr"
```

## USAGE

### Deploy with Separate Vars
```bash
# Automatically uses pr_vars.yml for PR, dr_vars.yml for DR
/home/ubuntu/Automate-Patch-Release/scripts/deploy_with_separate_vars.sh user-service /path/to/app.jar
```

### Manual Deployment
```bash
# Deploy to PR (uses pr_vars.yml)
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/deploy_separate_vars.yml \
  -e "target_env=pr" \
  -e "service=user-service" \
  -e "artifact=/path/to/app.jar"

# Deploy to DR (uses dr_vars.yml)
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/deploy_separate_vars.yml \
  -e "target_env=dr" \
  -e "service=user-service" \
  -e "artifact=/path/to/app.jar"
```

## VARIABLES AVAILABLE

### From pr_vars.yml (PR Environment)
- pr_env_name
- pr_datacenter
- pr_paths (backup_dir, artifact_dir, log_dir)
- pr_ports (service_port, admin_port, metrics_port)
- pr_database (host, port, name, pool_size)
- pr_cache (redis_host, redis_port)
- pr_jvm (max_heap, min_heap, gc_type)
- pr_limits (max_cpu_percent, max_memory_percent)
- pr_timeouts (service_stop, service_start)

### From dr_vars.yml (DR Environment)
- dr_env_name
- dr_datacenter
- dr_paths (backup_dir, artifact_dir, log_dir)
- dr_ports (service_port, admin_port, metrics_port)
- dr_database (host, port, name, pool_size)
- dr_cache (redis_host, redis_port)
- dr_jvm (max_heap, min_heap, gc_type)
- dr_limits (max_cpu_percent, max_memory_percent)
- dr_timeouts (service_stop, service_start)

## BENEFITS

✅ Complete separation of PR and DR configs
✅ Easy to maintain different values
✅ No hardcoded values
✅ Environment-specific settings
✅ Single playbook for both environments

## EXAMPLE

### PR Config (pr_vars.yml)
```yaml
pr_database:
  host: "pr-db-master.company.local"
  port: 5432
  
pr_jvm:
  max_heap: "8g"
  min_heap: "4g"
```

### DR Config (dr_vars.yml)
```yaml
dr_database:
  host: "dr-db-master.company.local"
  port: 5432
  
dr_jvm:
  max_heap: "8g"
  min_heap: "4g"
```

### Deployment
```bash
# Deploy to PR → uses pr_database.host
# Deploy to DR → uses dr_database.host
/home/ubuntu/Automate-Patch-Release/scripts/deploy_with_separate_vars.sh myapp /path/to/app.jar
```

---
✅ PR and DR variables in separate files
✅ Automatic loading based on target_env
✅ No hardcoded values
✅ Easy to maintain
