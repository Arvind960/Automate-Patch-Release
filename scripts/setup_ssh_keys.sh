#!/bin/bash
# ============================================
# SETUP SSH KEYS ON ALL SERVERS
# ============================================

PUBLIC_KEY=$(cat /root/.ssh/deploy_key.pub)
INVENTORY_FILE="/etc/ansible/hosts"

usage() {
    echo "Usage: $0 [-e environment] [-p password]"
    echo ""
    echo "Options:"
    echo "  -e    Environment (pr, dr, or all) [default: all]"
    echo "  -p    Root password for servers (will prompt if not provided)"
    echo ""
    echo "Examples:"
    echo "  $0 -e pr -p 'YourPassword'"
    echo "  $0 -e all"
    echo ""
    exit 1
}

# Default values
ENVIRONMENT="all"
PASSWORD=""

# Parse arguments
while getopts "e:p:h" opt; do
    case $opt in
        e) ENVIRONMENT=$OPTARG ;;
        p) PASSWORD=$OPTARG ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Prompt for password if not provided
if [ -z "$PASSWORD" ]; then
    read -sp "Enter root password for servers: " PASSWORD
    echo ""
fi

echo "=========================================="
echo "SSH KEY DISTRIBUTION"
echo "=========================================="
echo ""
echo "Public Key:"
echo "$PUBLIC_KEY"
echo ""
echo "=========================================="
echo ""

# Function to setup SSH key on a server
setup_key() {
    local HOST=$1
    local ENV=$2
    
    echo -n "Setting up $HOST ($ENV)... "
    
    # Use sshpass to copy key
    sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/deploy_key.pub root@$HOST 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Success"
        return 0
    else
        echo "❌ Failed"
        return 1
    fi
}

# Get list of servers based on environment
if [ "$ENVIRONMENT" == "all" ]; then
    SERVERS=$(ansible-inventory --list | jq -r '.pr_servers.hosts[], .dr_servers.hosts[]' 2>/dev/null)
elif [ "$ENVIRONMENT" == "pr" ]; then
    SERVERS=$(ansible-inventory --list | jq -r '.pr_servers.hosts[]' 2>/dev/null)
elif [ "$ENVIRONMENT" == "dr" ]; then
    SERVERS=$(ansible-inventory --list | jq -r '.dr_servers.hosts[]' 2>/dev/null)
else
    echo "Error: Invalid environment. Use 'pr', 'dr', or 'all'"
    exit 1
fi

# Setup keys on all servers
SUCCESS=0
FAILED=0

for SERVER in $SERVERS; do
    # Get IP address
    IP=$(ansible-inventory --host $SERVER | jq -r '.ansible_host' 2>/dev/null)
    
    if [ -n "$IP" ] && [ "$IP" != "null" ]; then
        if setup_key "$IP" "$SERVER"; then
            ((SUCCESS++))
        else
            ((FAILED++))
        fi
    fi
done

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo ""

if [ $SUCCESS -gt 0 ]; then
    echo "Test connectivity:"
    echo "  ansible all -m ping"
fi
