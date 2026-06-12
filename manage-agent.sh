#!/bin/bash
#
# CloudWatch Agent Management Utility
# Provides common operations: start, stop, restart, reconfigure, etc.
#

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AGENT_BIN="/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent"
AGENT_CTL="/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl"
CONFIG_FILE="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
LOG_FILE="/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"

print_usage() {
    echo -e "${BLUE}CloudWatch Agent Management Utility${NC}"
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  start              Start the CloudWatch Agent service"
    echo "  stop               Stop the CloudWatch Agent service"
    echo "  restart            Restart the CloudWatch Agent service"
    echo "  status             Show service status and statistics"
    echo "  enable             Enable service on boot"
    echo "  disable            Disable service on boot"
    echo "  reconfigure        Run interactive configuration wizard"
    echo "  fetch-config       Reload configuration from file"
    echo "  logs               Tail agent logs in real-time"
    echo "  logs-tail N        Show last N lines of logs"
    echo "  health             Run comprehensive health check"
    echo "  metrics            List collected metrics"
    echo "  version            Show agent version"
    echo "  help               Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  sudo $0 start"
    echo "  sudo $0 status"
    echo "  sudo $0 logs"
    echo "  sudo $0 logs-tail 50"
    echo "  sudo $0 health"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[ERROR] This script must be run as root${NC}"
    exit 1
fi

case "$1" in
    start)
        echo -e "${YELLOW}Starting CloudWatch Agent...${NC}"
        systemctl start amazon-cloudwatch-agent
        sleep 1
        if systemctl is-active --quiet amazon-cloudwatch-agent; then
            echo -e "${GREEN}[OK] CloudWatch Agent started${NC}"
        else
            echo -e "${RED}[ERROR] Failed to start CloudWatch Agent${NC}"
            exit 1
        fi
        ;;
    
    stop)
        echo -e "${YELLOW}Stopping CloudWatch Agent...${NC}"
        systemctl stop amazon-cloudwatch-agent
        sleep 1
        echo -e "${GREEN}[OK] CloudWatch Agent stopped${NC}"
        ;;
    
    restart)
        echo -e "${YELLOW}Restarting CloudWatch Agent...${NC}"
        systemctl restart amazon-cloudwatch-agent
        sleep 2
        if systemctl is-active --quiet amazon-cloudwatch-agent; then
            echo -e "${GREEN}[OK] CloudWatch Agent restarted${NC}"
        else
            echo -e "${RED}[ERROR] Failed to restart CloudWatch Agent${NC}"
            exit 1
        fi
        ;;
    
    status)
        echo -e "${BLUE}===============================================${NC}"
        echo -e "${BLUE}CloudWatch Agent Status${NC}"
        echo -e "${BLUE}===============================================${NC}"
        
        # Service status
        echo -e "${YELLOW}Service Status:${NC}"
        systemctl status amazon-cloudwatch-agent --no-pager | head -10
        echo ""
        
        # Process info
        echo -e "${YELLOW}Process Information:${NC}"
        if ps aux | grep -v grep | grep amazon-cloudwatch-agent > /dev/null; then
            ps aux | grep amazon-cloudwatch-agent | grep -v grep
        else
            echo "No process running"
        fi
        echo ""
        
        # Agent version
        echo -e "${YELLOW}Agent Version:${NC}"
        $AGENT_BIN -version
        echo ""
        
        # Configuration file
        if [ -f "$CONFIG_FILE" ]; then
            echo -e "${YELLOW}Configuration File:${NC}"
            echo "  Location: $CONFIG_FILE"
            echo "  Size: $(du -h "$CONFIG_FILE" | cut -f1)"
            echo "  Modified: $(stat -f "%Sm" "$CONFIG_FILE" 2>/dev/null || stat --format='%y' "$CONFIG_FILE" | cut -d' ' -f1-2)"
        else
            echo -e "${RED}Configuration file not found${NC}"
        fi
        echo ""
        
        # Metrics count
        if [ -f "$CONFIG_FILE" ]; then
            echo -e "${YELLOW}Configured Metrics:${NC}"
            METRIC_COUNT=$(grep -o '"measurement"' "$CONFIG_FILE" | wc -l)
            echo "  Metric groups: $METRIC_COUNT"
        fi
        echo ""
        
        # Recent log lines
        echo -e "${YELLOW}Recent Log Entries:${NC}"
        if [ -f "$LOG_FILE" ]; then
            tail -5 "$LOG_FILE"
        else
            echo "No log file found"
        fi
        ;;
    
    enable)
        echo -e "${YELLOW}Enabling CloudWatch Agent on boot...${NC}"
        systemctl enable amazon-cloudwatch-agent
        echo -e "${GREEN}[OK] Service enabled${NC}"
        ;;
    
    disable)
        echo -e "${YELLOW}Disabling CloudWatch Agent on boot...${NC}"
        systemctl disable amazon-cloudwatch-agent
        echo -e "${GREEN}[OK] Service disabled${NC}"
        ;;
    
    reconfigure)
        echo -e "${YELLOW}Running configuration wizard...${NC}"
        echo -e "${BLUE}Note: This will overwrite the existing configuration${NC}"
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            exit 0
        fi
        
        /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard
        
        read -p "Restart service with new configuration? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl restart amazon-cloudwatch-agent
            echo -e "${GREEN}[OK] Service restarted with new configuration${NC}"
        fi
        ;;
    
    fetch-config)
        echo -e "${YELLOW}Reloading configuration...${NC}"
        $AGENT_CTL -m ec2 -c file:"$CONFIG_FILE" -a fetch-config
        echo -e "${YELLOW}Restarting service...${NC}"
        systemctl restart amazon-cloudwatch-agent
        echo -e "${GREEN}[OK] Configuration reloaded${NC}"
        ;;
    
    logs)
        echo -e "${YELLOW}Tailing CloudWatch Agent logs (Ctrl+C to stop)...${NC}"
        tail -f "$LOG_FILE"
        ;;
    
    logs-tail)
        if [ -z "$2" ]; then
            LINES=20
        else
            LINES="$2"
        fi
        echo -e "${YELLOW}Last $LINES lines of CloudWatch Agent logs:${NC}"
        tail -"$LINES" "$LOG_FILE"
        ;;
    
    health)
        echo -e "${BLUE}===============================================${NC}"
        echo -e "${BLUE}CloudWatch Agent Health Check${NC}"
        echo -e "${BLUE}===============================================${NC}"
        
        ERRORS=0
        WARNINGS=0
        
        # Check 1: Binary exists
        echo -n "Agent binary exists... "
        if [ -f "$AGENT_BIN" ]; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            ((ERRORS++))
        fi
        
        # Check 2: Service running
        echo -n "Service running... "
        if systemctl is-active --quiet amazon-cloudwatch-agent; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            ((ERRORS++))
        fi
        
        # Check 3: Service enabled on boot
        echo -n "Service enabled on boot... "
        if systemctl is-enabled --quiet amazon-cloudwatch-agent; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${YELLOW}WARNING${NC}"
            ((WARNINGS++))
        fi
        
        # Check 4: Configuration file
        echo -n "Configuration file exists... "
        if [ -f "$CONFIG_FILE" ]; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            ((ERRORS++))
        fi
        
        # Check 5: Process running
        echo -n "Process running... "
        if pgrep -f amazon-cloudwatch-agent > /dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            ((ERRORS++))
        fi
        
        # Check 6: Log file accessible
        echo -n "Log file accessible... "
        if [ -f "$LOG_FILE" ] && [ -r "$LOG_FILE" ]; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            ((ERRORS++))
        fi
        
        # Check 7: IAM role available
        echo -n "IAM role available... "
        if curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null | grep -q .; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${YELLOW}WARNING (not on EC2 or no role)${NC}"
            ((WARNINGS++))
        fi
        
        echo ""
        echo -e "${RED}Errors: $ERRORS${NC}"
        echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
        
        if [ $ERRORS -eq 0 ]; then
            echo -e "${GREEN}Health check passed!${NC}"
            exit 0
        else
            echo -e "${RED}Health check failed${NC}"
            exit 1
        fi
        ;;
    
    metrics)
        echo -e "${BLUE}===============================================${NC}"
        echo -e "${BLUE}CloudWatch Agent Metrics Configuration${NC}"
        echo -e "${BLUE}===============================================${NC}"
        
        if [ -f "$CONFIG_FILE" ]; then
            echo "Metrics namespace: $(jq -r '.metrics.namespace' "$CONFIG_FILE")"
            echo "Collection interval: $(jq -r '.agent.metrics_collection_interval' "$CONFIG_FILE") seconds"
            echo ""
            echo "Configured metric groups:"
            jq '.metrics.metrics_collected | keys[]' "$CONFIG_FILE"
            echo ""
            echo "Full metrics configuration:"
            jq '.metrics' "$CONFIG_FILE"
        else
            echo -e "${RED}Configuration file not found${NC}"
            exit 1
        fi
        ;;
    
    version)
        $AGENT_BIN -version
        ;;
    
    help|--help|-h)
        print_usage
        ;;
    
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac
