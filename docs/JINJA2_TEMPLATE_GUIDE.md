# Jinja2 Template Engine Guide

## What is Jinja2?

Jinja2 is a modern templating engine for Python that allows you to create dynamic configuration files by embedding variables and logic into templates.

## Why We Use Jinja2

In our PR-DR automation, Jinja2 is used to generate environment-specific configuration files automatically:

- **One template** → Multiple configurations (PR and DR)
- **No manual editing** of configuration files
- **Consistent** across all 100+ servers
- **Environment-specific** values from pr_vars.yml and dr_vars.yml

## Installation

Jinja2 is automatically installed with Ansible. No separate installation needed!

```bash
# Jinja2 comes with Ansible
sudo apt install -y ansible

# Verify (optional)
python3 -c "import jinja2; print(jinja2.__version__)"
```

## How It Works in Our Setup

### 1. Template File Structure

**File:** `templates/microservice.service.j2`

```jinja
[Unit]
Description={{ service_name }} Microservice - {{ environment }}
After=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory={{ env_paths.artifact_dir }}/{{ service_name }}

# Java execution with environment-specific settings
ExecStart=/usr/bin/java \
  -Xmx{{ env_jvm.max_heap }} \
  -Xms{{ env_jvm.min_heap }} \
  -XX:+Use{{ env_jvm.gc_type }} \
  -jar {{ env_paths.artifact_dir }}/{{ service_name }}/current.jar \
  --server.port={{ env_ports.service_port }} \
  --management.port={{ env_ports.admin_port }} \
  --spring.datasource.url=jdbc:postgresql://{{ env_database.host }}:{{ env_database.port }}/{{ env_database.name }} \
  --spring.datasource.username={{ vault_db_user }} \
  --spring.datasource.password={{ vault_db_password }} \
  --spring.redis.host={{ env_cache.redis_host }} \
  --spring.redis.port={{ env_cache.redis_port }}

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

# Restart policy
Restart=always
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier={{ service_name }}

[Install]
WantedBy=multi-user.target
```

### 2. Variable Files

**PR Variables (config/pr_vars.yml):**
```yaml
pr_env_name: "production"
pr_datacenter: "primary"

pr_paths:
  artifact_dir: "/opt/artifacts/pr"
  log_dir: "/var/log/applications/pr"

pr_ports:
  service_port: 8080
  admin_port: 8081

pr_database:
  host: "pr-db-master.company.local"
  port: 5432
  name: "production_db"

pr_cache:
  redis_host: "pr-redis-master.company.local"
  redis_port: 6379

pr_jvm:
  max_heap: "8g"
  min_heap: "4g"
  gc_type: "G1GC"
```

**DR Variables (config/dr_vars.yml):**
```yaml
dr_env_name: "disaster_recovery"
dr_datacenter: "secondary"

dr_paths:
  artifact_dir: "/opt/artifacts/dr"
  log_dir: "/var/log/applications/dr"

dr_ports:
  service_port: 8080
  admin_port: 8081

dr_database:
  host: "dr-db-master.company.local"
  port: 5432
  name: "dr_db"

dr_cache:
  redis_host: "dr-redis-master.company.local"
  redis_port: 6379

dr_jvm:
  max_heap: "8g"
  min_heap: "4g"
  gc_type: "G1GC"
```

### 3. Ansible Playbook Usage

**In playbooks/deploy_separate_vars.yml:**
```yaml
- name: Update service configuration
  template:
    src: "{{ playbook_dir }}/../templates/microservice.service.j2"
    dest: "/etc/systemd/system/{{ service_name }}.service"
    mode: '0644'
```

### 4. Generated Output

**For PR Environment:**
```ini
[Unit]
Description=user-service Microservice - production
After=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/opt/artifacts/pr/user-service

ExecStart=/usr/bin/java \
  -Xmx8g \
  -Xms4g \
  -XX:+UseG1GC \
  -jar /opt/artifacts/pr/user-service/current.jar \
  --server.port=8080 \
  --management.port=8081 \
  --spring.datasource.url=jdbc:postgresql://pr-db-master.company.local:5432/production_db \
  --spring.redis.host=pr-redis-master.company.local \
  --spring.redis.port=6379

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**For DR Environment:**
```ini
[Unit]
Description=user-service Microservice - disaster_recovery
After=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/opt/artifacts/dr/user-service

ExecStart=/usr/bin/java \
  -Xmx8g \
  -Xms4g \
  -XX:+UseG1GC \
  -jar /opt/artifacts/dr/user-service/current.jar \
  --server.port=8080 \
  --management.port=8081 \
  --spring.datasource.url=jdbc:postgresql://dr-db-master.company.local:5432/dr_db \
  --spring.redis.host=dr-redis-master.company.local \
  --spring.redis.port=6379

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Jinja2 Syntax Reference

### Variables
```jinja
{{ variable_name }}              # Simple variable
{{ dict.key }}                   # Dictionary access
{{ list[0] }}                    # List access
{{ env_database.host }}          # Nested dictionary
```

### Conditionals
```jinja
{% if environment == 'pr' %}
Environment=SPRING_PROFILES_ACTIVE=production
{% elif environment == 'dr' %}
Environment=SPRING_PROFILES_ACTIVE=disaster-recovery
{% else %}
Environment=SPRING_PROFILES_ACTIVE=default
{% endif %}
```

### Loops
```jinja
{% for port in additional_ports %}
ExposedPort={{ port }}
{% endfor %}
```

### Filters
```jinja
{{ service_name | upper }}       # UPPERCASE
{{ service_name | lower }}       # lowercase
{{ path | basename }}            # Get filename
{{ value | default('N/A') }}     # Default value
```

### Comments
```jinja
{# This is a comment - won't appear in output #}
```

## Configuration Steps

### Step 1: Create Template File

```bash
cd /home/ubuntu/Automate-Patch-Release
vi templates/microservice.service.j2
```

Add your template with Jinja2 variables (see example above).

### Step 2: Update Variable Files

```bash
# Edit PR variables
vi config/pr_vars.yml

# Edit DR variables
vi config/dr_vars.yml
```

### Step 3: Use in Playbook

```yaml
- name: Generate configuration from template
  template:
    src: templates/microservice.service.j2
    dest: /etc/systemd/system/{{ service_name }}.service
```

### Step 4: Test Template Rendering

```bash
# Test with Ansible
ansible localhost -m template \
  -a "src=templates/microservice.service.j2 dest=/tmp/test.service" \
  -e "service_name=test-service" \
  -e "@config/pr_vars.yml"

# View generated file
cat /tmp/test.service
```

## Best Practices

### 1. Use Descriptive Variable Names
```jinja
# Good
{{ env_database.host }}

# Bad
{{ db_h }}
```

### 2. Provide Default Values
```jinja
{{ service_port | default(8080) }}
{{ max_heap | default('4g') }}
```

### 3. Add Comments
```jinja
{# Database configuration for {{ environment }} environment #}
--spring.datasource.url=jdbc:postgresql://{{ env_database.host }}
```

### 4. Keep Templates Simple
- One template per file type
- Avoid complex logic in templates
- Put logic in playbooks, not templates

### 5. Validate Generated Files
```yaml
- name: Validate generated config
  command: systemd-analyze verify {{ service_name }}.service
```

## Troubleshooting

### Issue: Variable Not Found
```
Error: 'dict object' has no attribute 'missing_var'
```
**Solution:** Check variable exists in pr_vars.yml or dr_vars.yml

### Issue: Syntax Error
```
Error: unexpected char '#' at line 10
```
**Solution:** Use `{# comment #}` not `# comment` for Jinja comments

### Issue: Template Not Rendering
```bash
# Debug: Print all variables
ansible-playbook playbook.yml -e "target_env=pr" --tags debug -vvv
```

## Summary

**Jinja2 in Our Setup:**
- ✅ **Installed:** Automatically with Ansible
- ✅ **Configuration:** No separate config needed
- ✅ **Usage:** Template files with `.j2` extension
- ✅ **Variables:** From pr_vars.yml and dr_vars.yml
- ✅ **Output:** Environment-specific configuration files

**Key Benefits:**
- One template → Multiple environments
- No manual configuration editing
- Consistent across all servers
- Easy to maintain and update

---

**Location:** `/home/ubuntu/Automate-Patch-Release/templates/`
**Documentation:** This guide
**Status:** Ready to use
