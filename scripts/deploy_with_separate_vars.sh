#!/bin/bash
# ============================================
# PR → DR DEPLOYMENT WITH SEPARATE VAR FILES
# ============================================

SERVICE=$1
ARTIFACT=$2

if [ -z "$SERVICE" ] || [ -z "$ARTIFACT" ]; then
    echo "Usage: $0 <service> <artifact>"
    exit 1
fi

# Verify artifact exists
if [ ! -f "$ARTIFACT" ]; then
    echo "❌ Artifact not found: $ARTIFACT"
    exit 1
fi

DEPLOY_PLAYBOOK="/home/ubuntu/Automate-Patch-Release/playbooks/deploy_separate_vars.yml"
VALIDATE_PLAYBOOK="/home/ubuntu/Automate-Patch-Release/playbooks/validate_separate_vars.yml"
ROLLBACK_PLAYBOOK="/home/ubuntu/Automate-Patch-Release/playbooks/secure_rollback.yml"

echo "=========================================="
echo "PR → DR DEPLOYMENT"
echo "Service: $SERVICE"
echo "Artifact: $ARTIFACT"
echo "=========================================="

# Deploy to PR (uses pr_vars.yml)
echo "▶ Deploying to PR (using pr_vars.yml)..."
if ! ansible-playbook $DEPLOY_PLAYBOOK \
  -e "target_env=pr" \
  -e "service=$SERVICE" \
  -e "artifact=$ARTIFACT"; then
  echo "❌ PR deployment failed"
  exit 1
fi

# Validate PR (uses pr_vars.yml)
echo "▶ Validating PR (using pr_vars.yml)..."
if ansible-playbook $VALIDATE_PLAYBOOK \
  -e "target_env=pr" \
  -e "service=$SERVICE"; then
  
  echo "✅ PR validation PASSED"
  
  # Deploy to DR (uses dr_vars.yml)
  echo "▶ Deploying to DR (using dr_vars.yml)..."
  if ! ansible-playbook $DEPLOY_PLAYBOOK \
    -e "target_env=dr" \
    -e "service=$SERVICE" \
    -e "artifact=$ARTIFACT"; then
    echo "❌ DR deployment failed"
    exit 1
  fi
  
  # Validate DR (uses dr_vars.yml)
  echo "▶ Validating DR (using dr_vars.yml)..."
  if ansible-playbook $VALIDATE_PLAYBOOK \
    -e "target_env=dr" \
    -e "service=$SERVICE"; then
    
    echo "✅ DR validation PASSED"
    echo "=========================================="
    echo "✅ SUCCESS - Both PR and DR updated"
    echo "=========================================="
    exit 0
  else
    echo "❌ DR validation FAILED - Rolling back DR"
    ansible-playbook $ROLLBACK_PLAYBOOK -e "target_env=dr" -e "service=$SERVICE"
    exit 1
  fi
else
  echo "❌ PR validation FAILED - Rolling back PR"
  ansible-playbook $ROLLBACK_PLAYBOOK -e "target_env=pr" -e "service=$SERVICE"
  exit 1
fi
