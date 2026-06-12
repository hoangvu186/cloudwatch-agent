#!/bin/bash
#
# CloudWatch Agent User Data Script for EC2
# This script is designed to run at EC2 launch time (via EC2 User Data)
# It will automatically install, configure, and start the CloudWatch Agent
#
# Usage: Paste content in EC2 Launch Wizard → Advanced Details → User Data
# Or: aws ec2 run-instances --user-data file://user-data.sh
#

set -ex

# Log all output
exec > >(tee /var/log/cloudwatch-agent-setup.log)
exec 2>&1

echo "=========================================="
echo "CloudWatch Agent User Data Script"
echo "=========================================="
echo "Start Time: $(date)"

# Update system
echo "Updating system packages..."
if command -v yum &> /dev/null; then
    yum update -y
    PKG_MANAGER="yum"
    AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
    AGENT_FILE="amazon-cloudwatch-agent.rpm"
elif command -v apt-get &> /dev/null; then
    apt-get update -y
    PKG_MANAGER="apt-get"
    AGENT_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
    AGENT_FILE="amazon-cloudwatch-agent.deb"
else
    echo "Unsupported package manager"
    exit 1
fi

# Download CloudWatch Agent
echo "Downloading CloudWatch Agent..."
cd /tmp
curl -s -O "$AGENT_URL"

# Install CloudWatch Agent
echo "Installing CloudWatch Agent..."
if [ "$PKG_MANAGER" = "yum" ]; then
    rpm -U "$AGENT_FILE"
elif [ "$PKG_MANAGER" = "apt-get" ]; then
    dpkg -i "$AGENT_FILE"
fi

# Verify installation
if [ -f /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent ]; then
    echo "✓ CloudWatch Agent installed successfully"
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent -version
else
    echo "✗ CloudWatch Agent installation failed"
    exit 1
fi

# Create minimal CloudWatch Agent configuration
# This can be replaced with a configuration stored in S3 or SSM Parameter Store
echo "Creating CloudWatch Agent configuration..."
cat > /tmp/cloudwatch-config.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "CustomApplication",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "unit": "Percent"},
          {"name": "cpu_usage_user", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "Environment": "Production"
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/system-logs",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
EOF

# Deploy configuration
echo "Deploying CloudWatch Agent configuration..."
cp /tmp/cloudwatch-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Enable and start CloudWatch Agent
echo "Enabling and starting CloudWatch Agent..."
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Wait for service to stabilize
sleep 3

# Verify service is running
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "✓ CloudWatch Agent is running"
else
    echo "✗ CloudWatch Agent failed to start"
    systemctl status amazon-cloudwatch-agent
    exit 1
fi

# Optional: Fetch configuration from SSM Parameter Store
# This allows centralized configuration management
# Uncomment to use:
#
# echo "Fetching configuration from SSM Parameter Store..."
# aws ssm get-parameter \
#   --name /cloudwatch-agent/config \
#   --query 'Parameter.Value' \
#   --output text \
#   --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region) \
#   > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
#
# systemctl restart amazon-cloudwatch-agent

echo "=========================================="
echo "Setup Complete!"
echo "End Time: $(date)"
echo "=========================================="
echo ""
echo "CloudWatch Agent Status:"
systemctl status amazon-cloudwatch-agent --no-pager
echo ""
echo "Next: Monitor in CloudWatch Console or via AWS CLI"
echo "  - Metrics: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:"
echo "  - Logs: https://console.aws.amazon.com/logs/home?region=us-east-1"
