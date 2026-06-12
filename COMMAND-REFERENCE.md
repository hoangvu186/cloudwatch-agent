# CloudWatch Agent - Command Reference Card

## Installation

```bash
# Option 1: Using package manager
sudo yum install amazon-cloudwatch-agent -y          # Amazon Linux/RHEL/CentOS

# Option 2: Manual download and install
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U amazon-cloudwatch-agent.rpm

# Option 3: Automated script
sudo bash quick-start.sh cloudwatch-config.json
```

---

## Configuration

```bash
# Interactive wizard
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard

# Using pre-built config
sudo cp cloudwatch-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# View current configuration
cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Validate JSON configuration
jq . /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

---

## Service Management

```bash
# Start agent
sudo systemctl start amazon-cloudwatch-agent

# Stop agent
sudo systemctl stop amazon-cloudwatch-agent

# Restart agent (reload config)
sudo systemctl restart amazon-cloudwatch-agent

# Check status
sudo systemctl status amazon-cloudwatch-agent

# Enable on boot
sudo systemctl enable amazon-cloudwatch-agent

# Disable on boot
sudo systemctl disable amazon-cloudwatch-agent

# Check if enabled
sudo systemctl is-enabled amazon-cloudwatch-agent

# Check if running
sudo systemctl is-active amazon-cloudwatch-agent
```

---

## Agent Control Commands

```bash
# Check agent version
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent -version

# Get agent status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 -a status

# Fetch configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -a fetch-config

# Stop agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 -a stop
```

---

## Logs and Debugging

```bash
# View recent logs (last 50 lines)
sudo tail -50 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Follow logs in real-time
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# View logs with timestamps
sudo tail -50 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log | grep -E "(ERROR|INFO|WARNING)"

# Full log view
sudo less /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Count errors in logs
sudo grep -i error /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log | wc -l

# Search for specific message
sudo grep "PutMetricData" /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

---

## Verification and Health Checks

```bash
# Comprehensive health check
sudo bash verify-agent.sh

# Using management utility
sudo bash manage-agent.sh health

# View full status report
sudo bash manage-agent.sh status

# Check process
ps aux | grep amazon-cloudwatch-agent | grep -v grep

# Check if listening/writing
lsof -p $(pgrep amazon-cloudwatch-agent) 2>/dev/null | head -20

# Verify IAM role
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Check EC2 instance metadata
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/ami-id
```

---

## CloudWatch Operations

```bash
# List metrics in custom namespace
aws cloudwatch list-metrics \
  --namespace "CustomApplication" \
  --region us-east-1

# List specific metric
aws cloudwatch list-metrics \
  --namespace "CustomApplication" \
  --metric-name "CPU_IDLE" \
  --region us-east-1

# Get metric statistics (last hour)
aws cloudwatch get-metric-statistics \
  --namespace "CustomApplication" \
  --metric-name "CPU_IDLE" \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --region us-east-1

# Describe log groups
aws logs describe-log-groups --region us-east-1

# List log streams in group
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/system-logs" \
  --region us-east-1

# View recent log events
aws logs tail /aws/ec2/system-logs --follow --region us-east-1

# Create log group (if needed)
aws logs create-log-group \
  --log-group-name "/aws/ec2/system-logs" \
  --region us-east-1

# Set log retention
aws logs put-retention-policy \
  --log-group-name "/aws/ec2/system-logs" \
  --retention-in-days 7 \
  --region us-east-1
```

---

## Management Utility Commands

```bash
# Start agent
sudo bash manage-agent.sh start

# Stop agent
sudo bash manage-agent.sh stop

# Restart agent
sudo bash manage-agent.sh restart

# View status
sudo bash manage-agent.sh status

# Health check
sudo bash manage-agent.sh health

# View logs live
sudo bash manage-agent.sh logs

# View last N log lines
sudo bash manage-agent.sh logs-tail 100

# Reconfigure (wizard)
sudo bash manage-agent.sh reconfigure

# Enable on boot
sudo bash manage-agent.sh enable

# Disable on boot
sudo bash manage-agent.sh disable

# Reload configuration
sudo bash manage-agent.sh fetch-config

# Show version
sudo bash manage-agent.sh version

# List configured metrics
sudo bash manage-agent.sh metrics

# Show help
sudo bash manage-agent.sh help
```

---

## Common Issues & Fixes

```bash
# Agent not starting
sudo systemctl restart amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent
sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Permission issues
sudo chown -R root:root /opt/aws/amazon-cloudwatch-agent
sudo chmod 755 /opt/aws/amazon-cloudwatch-agent/bin/*

# Invalid configuration
jq . /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
# Fix errors then reload:
sudo systemctl restart amazon-cloudwatch-agent

# No metrics appearing
# Check: IAM role, log files
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
ls -la /var/log/messages /var/log/secure

# Log files not collected
# Check file exists and is readable:
ls -la /var/log/messages
sudo -u cwagent cat /var/log/messages | head

# High CPU usage by agent
# Increase collection interval in config
# Reduce number of metrics
# Check log file sizes

# No IAM role/credentials
# Attach EC2 IAM role: 
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=CloudWatchAgentRole
```

---

## Configuration File Editing

```bash
# Backup configuration before editing
sudo cp /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
       /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json.bak

# Edit configuration
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Validate JSON
sudo jq . /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Apply changes
sudo systemctl restart amazon-cloudwatch-agent

# Restore from backup if needed
sudo cp /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json.bak \
       /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl restart amazon-cloudwatch-agent
```

---

## Bulk Deployment (Multiple Instances)

```bash
# Deploy to all Production instances
sudo bash deploy-bulk.sh cloudwatch-config.json "Environment=Production"

# Deploy to specific instances
aws ssm send-command \
  --instance-ids i-xxxxx i-yyyyy i-zzzzz \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo systemctl restart amazon-cloudwatch-agent"]' \
  --region us-east-1
```

---

## CloudFormation

```bash
# Create stack
aws cloudformation create-stack \
  --stack-name cloudwatch-agent-lab \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=my-keypair \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name cloudwatch-agent-lab \
  --query 'Stacks[0].Outputs' \
  --region us-east-1

# Delete stack
aws cloudformation delete-stack \
  --stack-name cloudwatch-agent-lab \
  --region us-east-1

# Watch stack creation
aws cloudformation wait stack-create-complete \
  --stack-name cloudwatch-agent-lab \
  --region us-east-1
```

---

## User Data (EC2 Launch)

```bash
# Deploy script as User Data when launching instance
# In AWS Console: EC2 → Launch Instance → Advanced Details → User Data
# Paste contents of: user-data.sh

# Or via CLI:
aws ec2 run-instances \
  --image-id ami-xxxxxxxxx \
  --instance-type t3.micro \
  --user-data file://user-data.sh \
  --key-name my-keypair \
  --iam-instance-profile Name=CloudWatchAgentRole \
  --region us-east-1
```

---

## Performance Tuning

```bash
# Increase collection interval (reduce cost)
# Edit config, change:
"metrics_collection_interval": 300   # Every 5 minutes instead of 1

# Collect specific metric only
# Edit config, keep only desired metrics

# Check memory usage
ps aux | grep amazon-cloudwatch-agent

# Check disk usage of logs
du -sh /opt/aws/amazon-cloudwatch-agent/logs/

# Reduce log verbosity (if needed)
# Check CloudWatch Agent source for verbosity settings
```

---

## Useful Directories

```
/opt/aws/amazon-cloudwatch-agent/              # Agent home
/opt/aws/amazon-cloudwatch-agent/bin/          # Binaries
/opt/aws/amazon-cloudwatch-agent/etc/          # Configuration
/opt/aws/amazon-cloudwatch-agent/logs/         # Log files
/var/log/messages                              # System logs (collected)
/var/log/secure                                # Security logs (collected)
/etc/systemd/system/amazon-cloudwatch-agent.service  # Systemd unit
```

---

## Quick Copy-Paste Commands

```bash
# Complete setup in one go
sudo yum install amazon-cloudwatch-agent -y && \
sudo cp cloudwatch-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json && \
sudo systemctl enable amazon-cloudwatch-agent && \
sudo systemctl start amazon-cloudwatch-agent && \
sudo systemctl status amazon-cloudwatch-agent

# Health check + view logs
sudo bash verify-agent.sh && sudo tail -20 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# List all metrics
aws cloudwatch list-metrics --namespace "CustomApplication" --query 'Metrics[*].MetricName' --output text

# View recent metrics
aws cloudwatch get-metric-statistics \
  --namespace "CustomApplication" \
  --metric-name "CPU_IDLE" \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

---

**Keep this card handy!**
