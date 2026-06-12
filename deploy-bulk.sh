#!/bin/bash
#
# CloudWatch Agent Deployment Script
# Deploys the CloudWatch Agent to multiple EC2 instances using AWS Systems Manager Session Manager
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REGION="${AWS_REGION:-us-east-1}"
CONFIG_FILE="${1:-cloudwatch-config.json}"
FILTER_TAG="${2:-Environment=Production}"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}CloudWatch Agent Bulk Deployment${NC}"
echo -e "${BLUE}===============================================${NC}"
echo "Region: $REGION"
echo "Config: $CONFIG_FILE"
echo "Tag Filter: $FILTER_TAG"

# Validate config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}[ERROR] Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Validate JSON
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${RED}[ERROR] Invalid JSON in configuration file${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Configuration file is valid${NC}"

# Get list of instances matching tag filter
echo -e "${YELLOW}Finding instances with tag filter: $FILTER_TAG${NC}"

IFS='=' read -r TAG_KEY TAG_VALUE <<< "$FILTER_TAG"
INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ -z "$INSTANCES" ]; then
    echo -e "${YELLOW}[INFO] No running instances found with tag $FILTER_TAG${NC}"
    exit 0
fi

INSTANCE_COUNT=$(echo "$INSTANCES" | wc -w)
echo -e "${GREEN}[OK] Found $INSTANCE_COUNT instances${NC}"
echo "$INSTANCES"

# Ask for confirmation
read -p "Deploy CloudWatch Agent to these instances? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Check SSM Agent status
echo -e "${YELLOW}Checking Systems Manager Agent status...${NC}"
for instance_id in $INSTANCES; do
    echo -n "Instance $instance_id: "
    status=$(aws ssm describe-instance-information \
        --region "$REGION" \
        --filters "Key=InstanceIds,Values=$instance_id" \
        --query 'InstanceInformationList[0].PingStatus' \
        --output text)
    
    if [ "$status" = "Online" ]; then
        echo -e "${GREEN}Online${NC}"
    else
        echo -e "${RED}$status${NC}"
    fi
done

# Encode configuration to base64 for command parameter
CONFIG_B64=$(base64 -w0 < "$CONFIG_FILE")

# Deploy to each instance
DEPLOYED=0
FAILED=0

for instance_id in $INSTANCES; do
    echo -e "${YELLOW}Deploying to $instance_id...${NC}"
    
    # Create command to download and install agent
    COMMAND="
set -e
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U amazon-cloudwatch-agent.rpm
echo '$CONFIG_B64' | base64 -d | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null
sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent
"
    
    # Send command via SSM
    COMMAND_ID=$(aws ssm send-command \
        --region "$REGION" \
        --instance-ids "$instance_id" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=$COMMAND" \
        --output-s3-bucket-name "" \
        --query 'Command.CommandId' \
        --output text)
    
    if [ -z "$COMMAND_ID" ]; then
        echo -e "${RED}[FAIL] Failed to send command to $instance_id${NC}"
        ((FAILED++))
        continue
    fi
    
    echo -e "${GREEN}[OK] Command sent: $COMMAND_ID${NC}"
    
    # Wait for command to complete
    for i in {1..30}; do
        sleep 1
        status=$(aws ssm get-command-invocation \
            --region "$REGION" \
            --command-id "$COMMAND_ID" \
            --instance-id "$instance_id" \
            --query 'Status' \
            --output text)
        
        if [ "$status" = "Success" ] || [ "$status" = "Failed" ] || [ "$status" = "Cancelled" ]; then
            break
        fi
    done
    
    if [ "$status" = "Success" ]; then
        echo -e "${GREEN}[PASS] Deployment successful${NC}"
        ((DEPLOYED++))
    else
        echo -e "${RED}[FAIL] Deployment failed: $status${NC}"
        ((FAILED++))
    fi
done

# Summary
echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}Deployment Summary${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}Deployed: $DEPLOYED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] All deployments completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}[WARNING] Some deployments failed${NC}"
    exit 1
fi
