#!/bin/bash
#
# CloudWatch Agent Verification Script
# Verifies installation, configuration, and status of CloudWatch Agent
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}CloudWatch Agent Verification${NC}"
echo -e "${BLUE}===============================================${NC}"

ERRORS=0
WARNINGS=0

# Check 1: Agent Binary Exists
echo -e "${YELLOW}[CHECK 1] Agent binary exists...${NC}"
if [ -f /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent ]; then
    echo -e "${GREEN}[PASS] Agent binary found${NC}"
else
    echo -e "${RED}[FAIL] Agent binary not found at /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent${NC}"
    ((ERRORS++))
fi

# Check 2: Agent Version
echo -e "${YELLOW}[CHECK 2] Agent version...${NC}"
VERSION=$(/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent -version 2>&1 || echo "Unable to determine")
echo -e "${GREEN}[INFO] Version: $VERSION${NC}"

# Check 3: Configuration File
echo -e "${YELLOW}[CHECK 3] Configuration file...${NC}"
if [ -f /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json ]; then
    echo -e "${GREEN}[PASS] Configuration file exists${NC}"
    echo -e "${YELLOW}Configuration summary:${NC}"
    cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json | grep -E '(namespace|metrics_collection_interval|log_group_name)' | head -10
else
    echo -e "${YELLOW}[WARNING] No configuration file found. Run configuration wizard.${NC}"
    ((WARNINGS++))
fi

# Check 4: Systemd Service
echo -e "${YELLOW}[CHECK 4] Systemd service status...${NC}"
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo -e "${GREEN}[PASS] Service is running${NC}"
    systemctl status amazon-cloudwatch-agent --no-pager | head -5
else
    echo -e "${YELLOW}[WARNING] Service is not running${NC}"
    ((WARNINGS++))
fi

# Check 5: Service enabled on boot
echo -e "${YELLOW}[CHECK 5] Service enabled on boot...${NC}"
if systemctl is-enabled --quiet amazon-cloudwatch-agent; then
    echo -e "${GREEN}[PASS] Service is enabled on boot${NC}"
else
    echo -e "${YELLOW}[WARNING] Service is not enabled on boot${NC}"
    ((WARNINGS++))
fi

# Check 6: Agent Process
echo -e "${YELLOW}[CHECK 6] Agent process...${NC}"
if pgrep -f "amazon-cloudwatch-agent" > /dev/null; then
    echo -e "${GREEN}[PASS] Agent process running${NC}"
    ps aux | grep amazon-cloudwatch-agent | grep -v grep
else
    echo -e "${YELLOW}[WARNING] Agent process not found${NC}"
    ((WARNINGS++))
fi

# Check 7: IAM Role
echo -e "${YELLOW}[CHECK 7] EC2 IAM Role and Permissions...${NC}"
IAM_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null || echo "")
if [ -n "$IAM_ROLE" ]; then
    echo -e "${GREEN}[PASS] IAM Role attached: $IAM_ROLE${NC}"
else
    echo -e "${RED}[FAIL] No IAM role found. CloudWatch Agent requires CloudWatchAgentServerPolicy${NC}"
    ((ERRORS++))
fi

# Check 8: CloudWatch Logs Permissions
echo -e "${YELLOW}[CHECK 8] Testing CloudWatch Logs access...${NC}"
if [ -n "$IAM_ROLE" ]; then
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    CREDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$IAM_ROLE)
    if echo "$CREDS" | grep -q "AccessKeyId"; then
        echo -e "${GREEN}[PASS] Can retrieve IAM credentials${NC}"
    else
        echo -e "${RED}[FAIL] Cannot retrieve IAM credentials${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}[SKIP] No IAM role to test${NC}"
fi

# Check 9: Disk Space
echo -e "${YELLOW}[CHECK 9] Disk space for logs...${NC}"
DISK_USAGE=$(df /var/log | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "${GREEN}[PASS] Disk usage: ${DISK_USAGE}%${NC}"
else
    echo -e "${RED}[WARNING] Disk usage high: ${DISK_USAGE}%${NC}"
    ((WARNINGS++))
fi

# Check 10: Log Files Readable
echo -e "${YELLOW}[CHECK 10] Log files readable...${NC}"
LOG_FILES=("/var/log/messages" "/var/log/secure" "/var/log/cloud-init-output.log")
for log in "${LOG_FILES[@]}"; do
    if [ -f "$log" ]; then
        if [ -r "$log" ]; then
            echo -e "${GREEN}[PASS] $log is readable${NC}"
        else
            echo -e "${YELLOW}[WARNING] $log is not readable${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}[INFO] $log does not exist${NC}"
    fi
done

# Summary
echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}Verification Summary${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "${RED}Errors: $ERRORS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] All critical checks passed!${NC}"
    exit 0
else
    echo -e "${RED}[FAILURE] Please fix the errors above${NC}"
    exit 1
fi
