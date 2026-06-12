# CloudWatch Agent Lab - Quick Start Guide

> **TL;DR**: 4 steps to get CloudWatch Agent running on EC2

## The 4 Steps (from the diagram)

### Step 1: Install the Agent Package

```bash
# Amazon Linux / RHEL / CentOS
sudo yum install amazon-cloudwatch-agent -y

# OR download and install manually
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U amazon-cloudwatch-agent.rpm
```

**What happens**:
- Agent binary installed to `/opt/aws/amazon-cloudwatch-agent/`
- Configuration wizard available at `/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard`

---

### Step 2: Run Configuration Wizard

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard
```

**The wizard asks about**:
1. Platform (EC2, On-Premises, etc.) → Select "EC2 instance"
2. OS (Linux, Windows) → Select "Linux"
3. Metrics collection (CPU, Memory, Disk, Network, Processes)
4. Log files to collect
5. Configuration location

**Output**: Creates `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`

**Or use pre-built config**:
```bash
sudo cp cloudwatch-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

---

### Step 3: Start the Agent

```bash
# Enable on boot
sudo systemctl enable amazon-cloudwatch-agent

# Start the service
sudo systemctl start amazon-cloudwatch-agent
```

**What happens**:
- Systemd service starts the agent process
- Agent reads configuration file
- Begins collecting metrics every 60 seconds (default)
- Begins sending logs to CloudWatch

---

### Step 4: Verify & Check Status

```bash
# Check if running
sudo systemctl status amazon-cloudwatch-agent

# View agent logs
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Check with agent CLI
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

**Expected signs of success**:
- ✓ Service shows "active (running)"
- ✓ No errors in logs
- ✓ Metrics appear in CloudWatch within 2-3 minutes
- ✓ Log streams created in CloudWatch Logs

---

## Quick Start Options

### Option A: Fastest (Automated)

```bash
# One command does everything!
sudo bash quick-start.sh cloudwatch-config.json
```

### Option B: Manual Step-by-Step

```bash
# Step 1
sudo bash install-cloudwatch-agent.sh

# Step 2
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard

# Step 3
sudo systemctl start amazon-cloudwatch-agent

# Step 4
sudo bash verify-agent.sh
```

### Option C: CloudFormation (for bulk deployment)

```bash
aws cloudformation create-stack \
  --stack-name cloudwatch-agent-lab \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=your-key-pair \
  --capabilities CAPABILITY_NAMED_IAM
```

### Option D: New EC2 Instance (auto-setup)

Use `user-data.sh` as User Data when launching EC2:
1. Go to EC2 Launch Wizard
2. Advanced Details → User Data
3. Paste content of `user-data.sh`
4. Instance comes up with agent already running!

---

## Before You Start: Prerequisites

### ✓ EC2 Instance Requirements
- OS: Amazon Linux 2, RHEL, CentOS, Ubuntu, or Debian
- Architecture: x86_64 or ARM64
- Root or sudo access
- SSH access (for manual setup)

### ✓ **CRITICAL**: IAM Role Must Be Attached

The EC2 instance **MUST** have an IAM role with these permissions:

```bash
# Easiest: Attach AWS managed policy
aws iam attach-role-policy \
  --role-name YourEC2Role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

**What does it do?**
- Allows agent to send metrics to CloudWatch
- Allows agent to create/write to CloudWatch Logs
- Allows agent to access EC2 metadata

**If you forget this**: Agent will start but fail silently (no errors visible until you check logs)

---

## File Guide

| File | Purpose | When to Use |
|------|---------|-------------|
| `quick-start.sh` | One-command setup | First time install |
| `install-cloudwatch-agent.sh` | Install only | Step 1 of manual setup |
| `cloudwatch-config.json` | Pre-built config | Skip the wizard |
| `verify-agent.sh` | Health check | Troubleshoot issues |
| `manage-agent.sh` | Agent control utility | Daily operations |
| `user-data.sh` | EC2 launch script | New instances |
| `deploy-bulk.sh` | Multi-instance deploy | Production rollout |
| `cloudformation-template.yaml` | Infrastructure as Code | Automated provisioning |
| `iam-policy.json` | IAM permissions | Policy reference |
| `README.md` | Full documentation | Detailed reference |

---

## Common Tasks

### View Metrics in CloudWatch

```bash
aws cloudwatch list-metrics \
  --namespace "CustomApplication" \
  --region us-east-1
```

Or go to: **CloudWatch Console → Metrics → CustomApplication**

### View Logs in CloudWatch

```bash
aws logs describe-log-groups --region us-east-1
aws logs tail /aws/ec2/system-logs --follow
```

Or go to: **CloudWatch Console → Logs → Log Groups**

### Change Collection Interval

Edit `cloudwatch-config.json`:
```json
{
  "agent": {
    "metrics_collection_interval": 300    // Every 5 minutes instead of 60 seconds
  }
}
```

Then reload:
```bash
sudo systemctl restart amazon-cloudwatch-agent
```

### Add New Metrics

Edit `cloudwatch-config.json` and add to `metrics_collected` section, then restart.

### Add New Log Files

Edit `cloudwatch-config.json` and add to `logs.logs_collected.files.collect_list`, then restart.

---

## Troubleshooting Quick Checklist

```bash
# 1. Is it running?
sudo systemctl status amazon-cloudwatch-agent

# 2. Any errors in logs?
sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# 3. Is IAM role attached?
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# 4. Is configuration valid?
jq . /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 5. Run full health check
sudo bash verify-agent.sh

# 6. Check metrics arriving
aws cloudwatch list-metrics --namespace "CustomApplication"
```

---

## What Gets Monitored (Default Config)

### Metrics (sent every 60 seconds)
- **CPU**: Usage (idle, user, system, iowait)
- **Memory**: Percent used, available
- **Disk**: Percent used
- **Network**: TCP connections (established, time_wait)
- **Processes**: Running, sleeping, total count

### Log Files (sent in real-time)
- `/var/log/messages` → `/aws/ec2/system-logs`
- `/var/log/secure` → `/aws/ec2/security-logs`
- `/var/log/cloud-init-output.log` → `/aws/ec2/cloud-init`

### Dimensions (attached to all metrics)
- Instance ID
- Image ID
- Instance Type
- Environment

---

## Monitoring the Monitors

Keep CloudWatch Agent itself healthy:

```bash
# Daily check
sudo bash manage-agent.sh health

# View agent logs
sudo bash manage-agent.sh logs

# Get full status report
sudo bash manage-agent.sh status

# List configured metrics
sudo bash manage-agent.sh metrics
```

---

## Cost Implications

**Metrics**: $0.30 per custom metric per month
**Logs**: $0.50 per GB ingested

**Default config example**:
- 20 metrics × 60 seconds/min × 1,440 min/day = ~43,200 data points/day
- Cost ≈ $0.30 × 20 metrics = $6/month for metrics
- Log costs depend on log volume (typically $1-5/month)

**Reduce costs**:
- Increase `metrics_collection_interval` to 300 seconds (every 5 min)
- Remove unused metrics
- Reduce log retention period

---

## AWS Console Links (Replace REGION)

- **Metrics**: `https://console.aws.amazon.com/cloudwatch/home?region=REGION#metricsV2:namespace=CustomApplication`
- **Logs**: `https://console.aws.amazon.com/logs/home?region=REGION#logStream:group=/aws/ec2/system-logs`
- **Alarms**: `https://console.aws.amazon.com/cloudwatch/home?region=REGION#alarmsV2:`

---

## Next Steps After Setup

1. **Create Alarms** - Alert when CPU > 80%, disk > 90%
2. **Create Dashboards** - Visualize key metrics
3. **Set Log Retention** - Reduce storage costs
4. **Create Log Filters** - Find errors automatically
5. **Set Up SNS Notifications** - Send alerts to team

---

## Getting Help

**Check docs first**:
```bash
less README.md          # Full documentation
cat QUICK-START.md      # This file
```

**Run verification**:
```bash
sudo bash verify-agent.sh
```

**Check logs**:
```bash
sudo tail -200 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log | grep -i error
```

**AWS Documentation**:
- CloudWatch Agent: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html
- Configuration Reference: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html

---

## Lab Success Criteria

✓ Agent installed  
✓ Configuration deployed  
✓ Service running  
✓ Metrics appearing in CloudWatch (2-3 min latency)  
✓ Logs appearing in CloudWatch Logs  
✓ Health check passing  

**Congratulations! Lab complete!** 🎉

---

**Last Updated**: 2024-01-15 | **Version**: 1.0
