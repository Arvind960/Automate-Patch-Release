# ============================================
# PR → DR DEPLOYMENT FLOW
# ============================================

## YOUR REQUIREMENT
✅ Apply patch/release to PR
✅ After successful PR deployment → Auto deploy to DR
✅ Same artifact deployed to both environments

## HOW IT WORKS

### Flow Diagram
```
Patch/Release Ready
        ↓
Deploy to PR (all servers)
        ↓
Validate PR (comprehensive checks)
        ↓
    [PASS?]
    ↙     ↘
  YES      NO
   ↓        ↓
Deploy    Rollback PR
to DR     Stop Pipeline
   ↓      Alert Team
Validate
  DR
   ↓
[PASS?]
 ↙   ↘
YES   NO
 ↓     ↓
✅    Rollback DR
     PR stays stable
```

## USAGE

### Option 1: Jenkins Pipeline (Recommended)
```groovy
// Trigger deployment
Build with Parameters:
- SERVICE_NAME: user-service
- ARTIFACT_PATH: /path/to/patch.jar
- CUSTOMER_ID: customer1

Pipeline automatically:
1. Deploys to PR
2. Validates PR
3. If PR passes → Deploys to DR
4. Validates DR
5. Rollback on any failure
```

### Option 2: Command Line
```bash
# Source environment
source /home/ubuntu/Automate-Patch-Release/config/environment.sh

# Deploy to PR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_deploy.yml \
  -e "target_env=pr" \
  -e "service=user-service" \
  -e "artifact=/path/to/patch.jar"

# Validate PR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_validate.yml \
  -e "target_env=pr" \
  -e "service=user-service"

# If PR validation passes, deploy to DR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_deploy.yml \
  -e "target_env=dr" \
  -e "service=user-service" \
  -e "artifact=/path/to/patch.jar"

# Validate DR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_validate.yml \
  -e "target_env=dr" \
  -e "service=user-service"
```

### Option 3: Single Script
```bash
#!/bin/bash
# /home/ubuntu/Automate-Patch-Release/scripts/deploy_pr_to_dr.sh

SERVICE=$1
ARTIFACT=$2

# Deploy to PR
ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_deploy.yml \
  -e "target_env=pr" -e "service=$SERVICE" -e "artifact=$ARTIFACT"

# Validate PR
if ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_validate.yml \
  -e "target_env=pr" -e "service=$SERVICE"; then
  
  echo "✅ PR validation passed. Deploying to DR..."
  
  # Deploy to DR
  ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_deploy.yml \
    -e "target_env=dr" -e "service=$SERVICE" -e "artifact=$ARTIFACT"
  
  # Validate DR
  ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_validate.yml \
    -e "target_env=dr" -e "service=$SERVICE"
else
  echo "❌ PR validation failed. Rolling back PR. DR not touched."
  ansible-playbook /home/ubuntu/Automate-Patch-Release/playbooks/secure_rollback.yml \
    -e "target_env=pr" -e "service=$SERVICE"
  exit 1
fi
```

## WHAT HAPPENS

### Scenario 1: Everything Passes ✅
```
1. Deploy patch to PR (all 100+ servers)
2. Validate PR → PASS
3. Deploy same patch to DR (all 100+ servers)
4. Validate DR → PASS
5. SUCCESS - Both environments updated
```

### Scenario 2: PR Fails ❌
```
1. Deploy patch to PR
2. Validate PR → FAIL
3. Rollback PR automatically
4. Stop pipeline
5. DR not touched (remains stable)
6. Alert sent
```

### Scenario 3: DR Fails ❌
```
1. Deploy patch to PR
2. Validate PR → PASS
3. Deploy patch to DR
4. Validate DR → FAIL
5. Rollback DR automatically
6. PR remains stable
7. Alert sent
```

## VALIDATIONS PERFORMED

### On Both PR and DR:
✅ Service status (running/stopped)
✅ Port availability
✅ Health endpoint (/health)
✅ Database connectivity
✅ API response time
✅ CPU usage < 85%
✅ Memory usage < 85%
✅ Disk usage < 90%
✅ Log errors < 5
✅ Business logic tests

## SETUP IN JENKINS

### Step 1: Create Pipeline Job
1. Jenkins → New Item → Pipeline
2. Name: "Deploy-PR-to-DR"
3. Pipeline script from SCM or paste Jenkinsfile

### Step 2: Configure Parameters
- SERVICE_NAME (string)
- ARTIFACT_PATH (string)
- CUSTOMER_ID (string, default: 'default')

### Step 3: Run
- Click "Build with Parameters"
- Enter service name and artifact path
- Click "Build"
- Watch automatic PR → DR deployment

## EXAMPLE DEPLOYMENT

### Deploy Patch
```bash
# Jenkins job or command line
SERVICE: payment-service
ARTIFACT: /opt/artifacts/payment-service-v2.1.5-patch.jar

Result:
- Deployed to PR: 50 servers in 3 minutes
- Validated PR: All checks passed
- Deployed to DR: 50 servers in 3 minutes
- Validated DR: All checks passed
- Total time: 8 minutes
- Status: SUCCESS ✅
```

### Deploy Release
```bash
SERVICE: user-service
ARTIFACT: /opt/artifacts/user-service-v3.0.0.jar

Result:
- Deployed to PR: 100 servers in 5 minutes
- Validated PR: All checks passed
- Deployed to DR: 100 servers in 5 minutes
- Validated DR: All checks passed
- Total time: 12 minutes
- Status: SUCCESS ✅
```

## KEY FEATURES

✅ **Same Artifact**: Exact same binary deployed to PR and DR
✅ **Automatic**: No manual intervention needed
✅ **Safe**: DR only deployed if PR succeeds
✅ **Fast**: Parallel deployment to all servers
✅ **Reliable**: Automatic rollback on failure
✅ **Audited**: Complete logs of all actions

## FILES INVOLVED

- **Pipeline**: /home/ubuntu/Automate-Patch-Release/jenkins/Jenkinsfile-PR-to-DR
- **Deploy**: /home/ubuntu/Automate-Patch-Release/playbooks/secure_deploy.yml
- **Validate**: /home/ubuntu/Automate-Patch-Release/playbooks/secure_validate.yml
- **Rollback**: /home/ubuntu/Automate-Patch-Release/playbooks/secure_rollback.yml
- **Inventory**: /home/ubuntu/Automate-Patch-Release/inventory/server_ips.yml

---
**Your Requirement**: ✅ FULLY SUPPORTED
**Status**: READY TO USE
