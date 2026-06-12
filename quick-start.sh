#!/bin/bash
#
# CloudWatch Agent Quick Start Script
# Automates: install, configure, start, and verify agent setup
# Usage: sudo bash quick-start.sh [config_file]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/cloudwatch-config.json}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}CloudWatch Agent Quick Start${NC}"
echo -e "${BLUE}===============================================${NC}"

# Run installation script
echo -e "${YELLOW}Running installation...${NC}"
if [ -f "$SCRIPT_DIR/install-cloudwatch-agent.sh" ]; then
    bash "$SCRIPT_DIR/install-cloudwatch-agent.sh"
else
    echo -e "${RED}[ERROR] install-cloudwatch-agent.sh not found${NC}"
    exit 1
fi

# Copy configuration if provided
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Copying configuration file...${NC}"
    sudo cp "$CONFIG_FILE" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    echo -e "${GREEN}[OK] Configuration deployed${NC}"
else
    echo -e "${YELLOW}[INFO] No configuration file found at $CONFIG_FILE${NC}"
    echo -e "${YELLOW}Running configuration wizard...${NC}"
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard
fi

# Start the agent
echo -e "${YELLOW}Starting CloudWatch Agent...${NC}"
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
sleep 2

# Verify status
echo -e "${YELLOW}Verifying status...${NC}"
if [ -f "$SCRIPT_DIR/verify-agent.sh" ]; then
    bash "$SCRIPT_DIR/verify-agent.sh"
else
    sudo systemctl status amazon-cloudwatch-agent
fi

echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}Quick Start Complete!${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  View agent logs:          sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
echo "  Restart agent:            sudo systemctl restart amazon-cloudwatch-agent"
echo "  Reconfigure agent:        sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard"
echo "  Check agent status:       sudo systemctl status amazon-cloudwatch-agent"
echo "  Stop agent:               sudo systemctl stop amazon-cloudwatch-agent"
