#!/bin/bash
#
# CloudWatch Agent Installation Script for EC2
# This script automates the installation and basic setup of the CloudWatch Agent
# Prerequisite: EC2 IAM Role must have CloudWatchAgentServerPolicy attached
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}CloudWatch Agent Installation Script${NC}"
echo -e "${BLUE}===============================================${NC}"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}[ERROR] Cannot detect OS${NC}"
    exit 1
fi

echo -e "${YELLOW}[INFO] Detected OS: $OS${NC}"

# Step 1: Update system packages
echo -e "${YELLOW}[STEP 1] Updating system packages...${NC}"
if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
    sudo yum update -y
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get update -y
else
    echo -e "${RED}[ERROR] Unsupported OS: $OS${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] System packages updated${NC}"

# Step 2: Download CloudWatch Agent
echo -e "${YELLOW}[STEP 2] Downloading CloudWatch Agent...${NC}"
AGENT_URL=""
AGENT_FILE=""

if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
        AGENT_FILE="amazon-cloudwatch-agent.rpm"
    elif [ "$ARCH" = "aarch64" ]; then
        AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/arm64/latest/amazon-cloudwatch-agent.rpm"
        AGENT_FILE="amazon-cloudwatch-agent.rpm"
    fi
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
        AGENT_FILE="amazon-cloudwatch-agent.deb"
    elif [ "$ARCH" = "aarch64" ]; then
        AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb"
        AGENT_FILE="amazon-cloudwatch-agent.deb"
    fi
fi

cd /tmp
curl -s "$AGENT_URL" -o "$AGENT_FILE"
if [ -f "$AGENT_FILE" ]; then
    echo -e "${GREEN}[OK] Agent downloaded: $AGENT_FILE${NC}"
else
    echo -e "${RED}[ERROR] Failed to download CloudWatch Agent${NC}"
    exit 1
fi

# Step 3: Install CloudWatch Agent
echo -e "${YELLOW}[STEP 3] Installing CloudWatch Agent...${NC}"
if [[ "$AGENT_FILE" == *.rpm ]]; then
    sudo rpm -U "$AGENT_FILE"
elif [[ "$AGENT_FILE" == *.deb ]]; then
    sudo dpkg -i "$AGENT_FILE"
fi

if [ -d /opt/aws/amazon-cloudwatch-agent ]; then
    echo -e "${GREEN}[OK] CloudWatch Agent installed successfully${NC}"
else
    echo -e "${RED}[ERROR] Installation failed${NC}"
    exit 1
fi

# Step 4: Verify installation
echo -e "${YELLOW}[STEP 4] Verifying installation...${NC}"
AGENT_VERSION=$(/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent -version 2>&1 || echo "Unknown")
echo -e "${GREEN}[OK] Agent version: $AGENT_VERSION${NC}"

# Step 5: Check IAM Role
echo -e "${YELLOW}[STEP 5] Checking EC2 IAM Role...${NC}"
INSTANCE_IDENTITY=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document 2>/dev/null || echo "Not on EC2 or no metadata")
if echo "$INSTANCE_IDENTITY" | grep -q "instanceId"; then
    echo -e "${GREEN}[OK] Running on EC2 instance${NC}"
    IAM_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null || echo "")
    if [ -z "$IAM_ROLE" ]; then
        echo -e "${YELLOW}[WARNING] No IAM role detected. Ensure EC2 instance has CloudWatchAgentServerPolicy${NC}"
    else
        echo -e "${GREEN}[OK] IAM Role found: $IAM_ROLE${NC}"
    fi
else
    echo -e "${YELLOW}[INFO] Not running on EC2 (testing environment)${NC}"
fi

echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}[SUCCESS] CloudWatch Agent installation complete!${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure the agent: sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard"
echo "   OR"
echo "   Copy config file: sudo cp /path/to/config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
echo ""
echo "2. Start the agent:"
echo "   sudo systemctl start amazon-cloudwatch-agent"
echo "   sudo systemctl enable amazon-cloudwatch-agent"
echo ""
echo "3. Check status:"
echo "   sudo systemctl status amazon-cloudwatch-agent"
echo "   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status"
