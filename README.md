# CloudWatch Agent Installation and Configuration Lab

Complete guide for installing, configuring, and verifying the CloudWatch Agent on EC2 instances.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [File Reference](#file-reference)

---

## Overview

The CloudWatch Agent is a unified tool to collect metrics and logs from your EC2 instances and on-premises servers. This lab covers:

1. **Install the Agent Package** - Download and install from AWS repositories
2. **Run Configuration Wizard** - Configure what metrics and logs to collect
3. **Start the Agent** - Enable and start the systemd service
4. **Verify & Check Status** - Confirm agent is running and collecting data

### What Gets Monitored

- **Metrics**: CPU, Memory, Disk usage, Network connections, Process count
- **Logs**: System messages, Security logs, Cloud-init output
- **Dimensions**: Instance ID, Image ID, Instance Type, Environment

---

## Prerequisites

### 1. EC2 Instance Requirements

- OS: Amazon Linux 2, RHEL, CentOS, Ubuntu, or Debian
- Architecture: x86_64 or ARM64 (aarch64)
- Root or sudo access

### 2. IAM Role Requirements

The EC2 instance **MUST** have an IAM role attached with the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "ec2:DescribeInstances",
        "logs:PutLogEvents",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
    }
  ]
}
```

**AWS managed policy** (recommended):
- `CloudWatchAgentServerPolicy` - AWSManaged policy

**How to attach**:
```bash
# Via AWS CLI
aws iam attach-role-policy \
  --role-name <YourEC2Role> \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Via AWS Console
1. Go to IAM → Roles
2. Select your EC2 role
3. Click "Attach Policies"
4. Search for "CloudWatchAgentServerPolicy"
5. Click Attach
```

---

## Installation Methods

### Method 1: Quick Start (Recommended)

Run the automated quick-start script:

```bash
cd /tmp
curl -O https://your-repo/quick-start.sh
chmod +x quick-start.sh
sudo bash quick-start.sh [optional_config_file]
```

### Method 2: Step-by-Step Manual

#### Step 1: Update System Packages

```bash
# Amazon Linux / RHEL / CentOS
sudo yum update -y

# Ubuntu / Debian
sudo apt-get update -y
```

#### Step 2: Download CloudWatch Agent

```bash
# Amazon Linux 2 / RHEL / CentOS (x86_64)
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm

# Ubuntu / Debian (x86_64)
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

# For ARM64 (aarch64), replace 'amd64' with 'arm64'
```

#### Step 3: Install Agent

```bash
# For RPM (Amazon Linux / RHEL / CentOS)
sudo rpm -U /tmp/amazon-cloudwatch-agent.rpm

# For DEB (Ubuntu / Debian)
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb
```

#### Step 4: Configure Agent

**Option A: Using Configuration Wizard (Interactive)**

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard
```

The wizard will ask:
1. Platform selection (EC2, On-premises, etc.)
2. Metrics collection (CPU, Memory, Disk, etc.)
3. Log files to collect
4. Save location

**Option B: Using Pre-built Configuration (Automatic)**

```bash
# Copy the provided config
sudo cp cloudwatch-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

#### Step 5: Start Agent

```bash
# Enable on boot
sudo systemctl enable amazon-cloudwatch-agent

# Start the service
sudo systemctl start amazon-cloudwatch-agent

# Check status
sudo systemctl status amazon-cloudwatch-agent
```

#### Step 6: Verify Status

```bash
# Check if running
sudo systemctl is-active amazon-cloudwatch-agent

# View agent logs
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Check using agent CLI
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 -a status

# View agent status and configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -a fetch-config
```

---

## Configuration

### Configuration File Structure

The `cloudwatch-config.json` file has three main sections:

#### 1. Agent Section

```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  }
}
```

- `metrics_collection_interval`: Collect metrics every 60 seconds
- `run_as_user`: Agent runs as root (required for system metrics)

#### 2. Metrics Section

Collects system performance data:

```json
{
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
        ]
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "unit": "Percent"}
        ]
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "Environment": "Production"
    }
  }
}
```

#### 3. Logs Section

Collects log files and sends to CloudWatch Logs:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/system-logs",
            "log_stream_name": "{instance_id}-messages",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
```

### Common Metric Options

| Metric | Available Fields | Unit |
|--------|------------------|------|
| CPU | cpu_usage_idle, cpu_usage_user, cpu_usage_system, cpu_usage_iowait | Percent |
| Memory | mem_used_percent, mem_available | Percent / Megabytes |
| Disk | used_percent, inodes_free | Percent / Count |
| Network | tcp_established, tcp_time_wait, udp_rcv | Count |
| Processes | running, sleeping, total | Count |

### Common Log Locations

| Log File | Purpose | Retention |
|----------|---------|-----------|
| `/var/log/messages` | System messages | 7 days |
| `/var/log/secure` | Authentication & security | 30 days |
| `/var/log/cloud-init-output.log` | EC2 initialization | 7 days |
| `/var/log/httpd/access_log` | Web server access | 7 days |
| `/var/log/httpd/error_log` | Web server errors | 30 days |

---

## Verification

### Method 1: Using Verification Script

```bash
sudo bash verify-agent.sh
```

This checks:
- ✓ Agent binary exists
- ✓ Configuration file present
- ✓ Service running and enabled
- ✓ IAM role attached
- ✓ CloudWatch permissions working
- ✓ Log files readable
- ✓ Disk space available

### Method 2: Manual Verification

#### Check Service Status

```bash
# Systemd status
sudo systemctl status amazon-cloudwatch-agent

# Expected output:
# ● amazon-cloudwatch-agent.service - Amazon CloudWatch Agent
#      Loaded: loaded (/etc/systemd/system/amazon-cloudwatch-agent.service; enabled; vendor preset: disabled)
#      Active: active (running) since Mon 2024-01-15 10:30:00 UTC
```

#### Check Process

```bash
ps aux | grep amazon-cloudwatch-agent

# Expected: /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent -config=/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

#### Check Agent Logs

```bash
sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Expected output shows: "Config has been written to...", "Metrics collected", etc.
```

#### Verify Metrics in CloudWatch

```bash
# List metrics in your custom namespace
aws cloudwatch list-metrics \
  --namespace "CustomApplication" \
  --region us-east-1
```

#### Verify Logs in CloudWatch

```bash
# List log groups
aws logs describe-log-groups \
  --query 'logGroups[*].logGroupName' \
  --region us-east-1

# View recent log entries
aws logs tail /aws/ec2/system-logs --follow
```

---

## Troubleshooting

### Issue: Agent Not Running

**Check Logs**:
```bash
sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

**Common Causes & Solutions**:

| Issue | Solution |
|-------|----------|
| Service not started | `sudo systemctl start amazon-cloudwatch-agent` |
| Dependency missing | `sudo systemctl start amazon-cloudwatch-agent` |
| Config file error | Validate JSON: `jq . /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json` |
| Permission denied | Ensure running as root: `sudo systemctl status amazon-cloudwatch-agent` |

### Issue: No IAM Role

**Error in logs**: `AccessDenied` or `NoCredentialProviders`

**Solution**:
```bash
# Verify role exists
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# If empty, attach role to instance:
aws ec2 associate-iam-instance-profile \
  --instance-id i-1234567890abcdef0 \
  --iam-instance-profile Name=YourEC2Role
```

### Issue: Configuration Not Applied

**Solution**:
```bash
# Reload configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -a fetch-config

# Restart agent
sudo systemctl restart amazon-cloudwatch-agent
```

### Issue: Missing Log Groups

**Check CloudWatch**:
```bash
aws logs describe-log-groups --region us-east-1
```

**Solution - Manual Creation**:
```bash
aws logs create-log-group \
  --log-group-name /aws/ec2/system-logs \
  --region us-east-1

# Set retention
aws logs put-retention-policy \
  --log-group-name /aws/ec2/system-logs \
  --retention-in-days 7 \
  --region us-east-1
```

### Issue: High Disk Usage by Agent

**Solution**:
```bash
# Check log rotation
sudo ls -lah /opt/aws/amazon-cloudwatch-agent/logs/

# Truncate if needed
sudo truncate -s 0 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Reduce metrics collection interval (increase value = less frequent)
# Edit cloudwatch-config.json, change:
# "metrics_collection_interval": 300  # Collect every 5 minutes instead of 1
```

### Issue: Permissions Error on Log Files

**Error**: `open /var/log/secure: permission denied`

**Solution**:
```bash
# Add cwagent user to necessary groups
sudo usermod -a -G adm cwagent
sudo usermod -a -G wheel cwagent

# Or change file permissions
sudo chmod 644 /var/log/secure
sudo chmod 644 /var/log/messages
```

---

## File Reference

### Installation Scripts

#### `install-cloudwatch-agent.sh`
- Detects OS (Amazon Linux, RHEL, CentOS, Ubuntu, Debian)
- Downloads appropriate agent package
- Installs agent binary
- Verifies IAM role
- Outputs next steps

**Usage**:
```bash
sudo bash install-cloudwatch-agent.sh
```

#### `quick-start.sh`
- Runs full installation workflow
- Deploys configuration
- Starts agent
- Runs verification

**Usage**:
```bash
sudo bash quick-start.sh [config_file]
sudo bash quick-start.sh cloudwatch-config.json
```

### Configuration Files

#### `cloudwatch-config.json`
Pre-configured agent settings including:
- 60-second metric collection interval
- CPU, Memory, Disk, Network metrics
- System logs collection
- CloudWatch Logs integration
- Automatic dimension tagging

**Location**: `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`

#### `iam-policy.json`
IAM policy granting required permissions:
- CloudWatch metrics PutMetricData
- EC2 describe operations (for tagging)
- CloudWatch Logs creation and writes
- SSM parameter access

**Usage**:
```bash
aws iam put-role-policy \
  --role-name YourEC2Role \
  --policy-name CloudWatchAgent \
  --policy-document file://iam-policy.json
```

### Verification & Monitoring

#### `verify-agent.sh`
Comprehensive health check script validating:
- Binary installation
- Configuration presence
- Service status and boot-time enablement
- IAM credentials accessibility
- Log file readability
- Disk space availability

**Usage**:
```bash
sudo bash verify-agent.sh
```

---

## Practical Examples

### Example 1: Monitor Web Server

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/webserver/access",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7,
            "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/webserver/errors",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  }
}
```

### Example 2: Custom Application Logs

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/myapp/logs/app.log",
            "log_group_name": "/aws/ec2/myapp/application",
            "log_stream_name": "{instance_id}-{ip_address}",
            "retention_in_days": 14,
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
```

### Example 3: High-Frequency Monitoring

```json
{
  "agent": {
    "metrics_collection_interval": 10,
    "run_as_user": "root"
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "metrics_collection_interval": 5
      },
      "mem": {
        "metrics_collection_interval": 5
      }
    }
  }
}
```

---

## Best Practices

1. **Use IAM Roles**: Always use IAM roles instead of access keys for EC2 instances
2. **Least Privilege**: Grant only necessary permissions via IAM policies
3. **Log Retention**: Set appropriate retention periods to manage costs
4. **Monitoring**: Enable alarms on critical metrics (high CPU, low disk space)
5. **Testing**: Test configuration changes in non-production first
6. **Documentation**: Document custom metrics and log streams
7. **Regular Checks**: Periodically verify agent status and connectivity
8. **Cost Optimization**: Adjust collection intervals based on requirements (higher interval = less cost)

---

## Quick Command Reference

```bash
# Installation & Setup
sudo rpm -U amazon-cloudwatch-agent.rpm              # Install (RPM)
sudo dpkg -i amazon-cloudwatch-agent.deb             # Install (DEB)
sudo bash quick-start.sh                             # Full automation

# Configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard

# Service Management
sudo systemctl start amazon-cloudwatch-agent         # Start
sudo systemctl stop amazon-cloudwatch-agent          # Stop
sudo systemctl restart amazon-cloudwatch-agent       # Restart
sudo systemctl status amazon-cloudwatch-agent        # Status
sudo systemctl enable amazon-cloudwatch-agent        # Enable on boot

# Verification & Monitoring
sudo bash verify-agent.sh                            # Full health check
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# CloudWatch Queries
aws cloudwatch list-metrics --namespace "CustomApplication"
aws logs describe-log-groups
aws logs tail /aws/ec2/system-logs --follow
```

---

## Support & Resources

- [AWS CloudWatch Agent Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [CloudWatch Agent Configuration Reference](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/)

---

**Last Updated**: 2024-01-15
**Version**: 1.0
**Author**: AWS Labs
