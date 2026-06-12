# CloudWatch Agent Lab - Complete File Index

## 📋 Overview

This lab provides a complete, production-ready implementation of the CloudWatch Agent installation and configuration process for EC2 instances. All four steps from the AWS training module are covered:

1. **Install the Agent Package**
2. **Run Configuration Wizard**
3. **Start the Agent**
4. **Verify & Check Status**

---

## 📁 File Structure

### 📖 Documentation Files

| File | Purpose | Audience | Read Time |
|------|---------|----------|-----------|
| **QUICK-START.md** | Fast 4-step guide | Everyone | 5 min |
| **README.md** | Comprehensive reference | Operators, Architects | 20 min |
| **COMMAND-REFERENCE.md** | Command cheat sheet | Operators | Reference |
| **FILE-INDEX.md** | This file | Navigation | 5 min |

**Start here**: 
- New to CloudWatch Agent? → Read `QUICK-START.md`
- Need details? → Read `README.md`
- Need a command? → Check `COMMAND-REFERENCE.md`

---

### 🔧 Installation & Setup Scripts

| File | Purpose | When to Use | Requires sudo |
|------|---------|------------|---------------|
| **quick-start.sh** | One-command full setup | First time, demo, lab | YES |
| **install-cloudwatch-agent.sh** | Download and install only | Step 1 manual setup | YES |
| **user-data.sh** | EC2 launch-time auto-setup | New EC2 instances | Auto-run |

**Quick decision tree**:
- "I want to set up one instance now" → `quick-start.sh`
- "I'm launching new instances in AWS" → Copy `user-data.sh` to EC2 User Data
- "I only need to install the binary" → `install-cloudwatch-agent.sh`

---

### ⚙️ Configuration Files

| File | Purpose | When to Use | Format |
|------|---------|------------|--------|
| **cloudwatch-config.json** | Pre-built agent configuration | Skip interactive wizard | JSON |
| **iam-policy.json** | IAM permissions template | Create/attach IAM role | JSON |

**Config includes**:
- 60-second metric collection
- CPU, Memory, Disk, Network, Process metrics
- System log file collection
- CloudWatch Logs integration
- Automatic dimension tagging

---

### 🛠️ Management & Utilities

| File | Purpose | When to Use | Requires sudo |
|------|---------|------------|---------------|
| **manage-agent.sh** | Agent control utility | Daily operations | YES |
| **verify-agent.sh** | Comprehensive health check | Troubleshooting | YES |
| **deploy-bulk.sh** | Multi-instance deployment | Production rollout | YES |

**Common operations**:
- `manage-agent.sh start/stop/restart` - Control service
- `manage-agent.sh health` - Full health check
- `verify-agent.sh` - Identify issues
- `deploy-bulk.sh` - Deploy to many instances

---

### 📦 Infrastructure as Code

| File | Purpose | When to Use | Tech |
|------|---------|------------|------|
| **cloudformation-template.yaml** | Full stack automation | CloudFormation users | AWS CF |

**Provisions**:
- IAM role with CloudWatch permissions
- Security group
- EC2 instance with agent pre-installed
- Log groups and metrics namespace

**Usage**:
```bash
aws cloudformation create-stack \
  --stack-name cloudwatch-lab \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=my-key \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## 🚀 Quick Start Paths

### Path 1: Manual Setup (Learning)

**Goal**: Understand each step

1. Read: `QUICK-START.md`
2. Run: `install-cloudwatch-agent.sh`
3. Run: `/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-config-wizard`
4. Run: `manage-agent.sh start`
5. Run: `verify-agent.sh`

**Time**: ~10 minutes

---

### Path 2: Automated Setup (Quick Demo)

**Goal**: Get running ASAP

```bash
sudo bash quick-start.sh cloudwatch-config.json
sudo bash verify-agent.sh
```

**Time**: ~2 minutes

---

### Path 3: Bulk Production Deployment

**Goal**: Deploy to many instances

1. Create IAM role with `iam-policy.json`
2. Attach to EC2 instances
3. Run: `deploy-bulk.sh cloudwatch-config.json "Environment=Production"`
4. Monitor: `manage-agent.sh health`

**Time**: ~5 minutes per instance + validation

---

### Path 4: New EC2 Instances (CloudFormation)

**Goal**: Automated, repeatable infrastructure

1. Update `cloudformation-template.yaml` for your needs
2. Run: 
   ```bash
   aws cloudformation create-stack \
     --stack-name cloudwatch-lab \
     --template-body file://cloudformation-template.yaml \
     --parameters ParameterKey=KeyName,ParameterValue=your-key \
     --capabilities CAPABILITY_NAMED_IAM
   ```
3. Done! Instances come up with agent ready

**Time**: ~3 minutes

---

### Path 5: Dynamic Instance Setup (User Data)

**Goal**: EC2 self-initialization

1. In EC2 Launch Wizard
2. Advanced Details → User Data
3. Paste contents of `user-data.sh`
4. Launch
5. Agent auto-starts in background

**Time**: ~1 minute per instance

---

## 📋 Lab Workflow

### Before You Start: Prerequisites

- [ ] AWS Account with EC2 access
- [ ] EC2 instance running (or launch one)
- [ ] IAM role attached with CloudWatch permissions
- [ ] SSH access to instance

**Check prerequisites**:
```bash
# 1. Instance running?
aws ec2 describe-instances --instance-ids i-xxxxx

# 2. IAM role attached?
aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values=i-xxxxx

# 3. IAM has permissions?
aws iam get-role-policy --role-name YourRole --policy-name CloudWatchAgent
```

---

### Lab Execution

**Option A: Manual (Understanding)**
1. SSH to instance
2. `wget https://your-repo/quick-start.sh`
3. `sudo bash quick-start.sh`
4. `sudo bash verify-agent.sh`
5. Check CloudWatch Console

**Option B: Scripted (Efficiency)**
```bash
cd /tmp
wget https://your-repo/quick-start.sh
sudo bash quick-start.sh cloudwatch-config.json
```

**Option C: Infrastructure (Reproducibility)**
```bash
aws cloudformation create-stack --stack-name lab --template-body file://cloudformation-template.yaml ...
```

---

### Validation Checklist

- [ ] Agent binary installed
- [ ] Configuration deployed
- [ ] Service running (`systemctl status`)
- [ ] Metrics in CloudWatch (2-3 min latency)
- [ ] Logs in CloudWatch Logs
- [ ] Health check passing (`verify-agent.sh`)

---

## 🔍 Detailed File Reference

### QUICK-START.md
- 4 steps explained
- 5 quick-start options
- Prerequisites with IAM role setup
- Common tasks
- Troubleshooting checklist
- Monitoring links

### README.md
- Overview and objectives
- Prerequisites (instance + IAM)
- Installation methods (manual + scripted)
- Configuration deep-dive
- Verification methods
- Extensive troubleshooting
- Best practices

### COMMAND-REFERENCE.md
- Installation commands
- Service management commands
- CloudWatch API commands
- Management utility commands
- Common issues & fixes
- Performance tuning
- Copy-paste ready commands

### quick-start.sh
- Detects OS (Amazon Linux, RHEL, Ubuntu, etc.)
- Downloads appropriate agent package
- Installs agent
- Deploys configuration
- Starts service
- Runs verification

### install-cloudwatch-agent.sh
- OS detection
- Package download
- Installation
- IAM role verification
- Output and next steps

### verify-agent.sh
- 10-point health check
- Service status
- Process verification
- IAM role check
- CloudWatch permissions test
- Log file accessibility
- Disk space check
- Detailed pass/fail report

### manage-agent.sh
- Service control (start, stop, restart)
- Status reporting
- Boot-time enabling/disabling
- Configuration reload
- Live log tailing
- Health checks
- Metrics listing
- 12 commands total

### cloudwatch-config.json
- Metrics: CPU, Memory, Disk, Network, Processes
- Logs: System logs, Security logs, Cloud-init
- Dimensions: InstanceId, ImageId, InstanceType, Environment
- 60-second collection interval
- CloudWatch Logs integration

### user-data.sh
- Runs at EC2 launch
- Installs agent
- Deploys configuration
- Starts service
- Logs all output to `/var/log/cloudwatch-agent-setup.log`

### cloudformation-template.yaml
- IAM role (CloudWatchAgentServerPolicy + SSM)
- Instance profile
- Security group
- EC2 instance with agent
- User data integration
- Outputs for easy reference

### deploy-bulk.sh
- Tag-based instance filtering
- Systems Manager Session Manager integration
- Parallel deployment simulation
- Status tracking
- Summary reporting

### iam-policy.json
- CloudWatch metrics permissions
- EC2 metadata permissions
- CloudWatch Logs permissions
- SSM parameter access
- Production-ready policy

---

## 📊 Feature Matrix

| Feature | Script | Config | Doc |
|---------|--------|--------|-----|
| OS Detection | quick-start, install | - | README |
| Package Download | quick-start, install | - | README |
| Installation | quick-start, install | - | README |
| Interactive Config | - | - | README |
| Pre-built Config | quick-start | cloudwatch-config.json | QUICK-START |
| Service Start | quick-start | - | README |
| Health Check | verify-agent | - | COMMAND-REF |
| Metrics Collection | - | cloudwatch-config.json | README |
| Log Collection | - | cloudwatch-config.json | README |
| Bulk Deploy | deploy-bulk | - | README |
| IAM Setup | - | iam-policy.json | README |
| CloudFormation | cloudformation-template.yaml | - | README |
| Management Utilities | manage-agent | - | COMMAND-REF |

---

## 🎯 Common Use Cases

### Use Case 1: "I need to monitor an EC2 instance now"
1. SSH to instance
2. Run: `sudo bash quick-start.sh cloudwatch-config.json`
3. Done!

### Use Case 2: "I'm deploying to 50 instances"
1. Run: `sudo bash deploy-bulk.sh cloudwatch-config.json "Team=Engineering"`
2. Monitor progress
3. Verify: `aws cloudwatch list-metrics --namespace CustomApplication`

### Use Case 3: "I'm launching a new environment"
1. Use: `cloudformation-template.yaml`
2. Deploy: `aws cloudformation create-stack ...`
3. Instances come up with agent ready

### Use Case 4: "I need to troubleshoot an agent"
1. Run: `sudo bash verify-agent.sh`
2. Read output, fix issues identified
3. Run: `sudo bash manage-agent.sh health`
4. Check logs: `sudo bash manage-agent.sh logs`

### Use Case 5: "I want to understand how it works"
1. Read: `QUICK-START.md` (5 min)
2. Read: `README.md` sections (20 min)
3. Follow Path 1 setup manually (10 min)
4. Explore: Check files, read documentation

---

## 🔗 File Dependencies

```
quick-start.sh
├── Calls: install-cloudwatch-agent.sh
├── Uses: cloudwatch-config.json
└── Calls: verify-agent.sh

deploy-bulk.sh
└── Uses: cloudwatch-config.json

cloudformation-template.yaml
├── Uses: iam-policy.json (embedded)
└── Runs: user-data.sh (embedded)

Documentation
├── QUICK-START.md → Points to COMMAND-REFERENCE.md
├── README.md → Links to external resources
├── COMMAND-REFERENCE.md → References all scripts/files
└── FILE-INDEX.md → This file

Management
└── manage-agent.sh (standalone)
```

---

## 💾 Installation

Clone or download all files to EC2 instance:

```bash
# Download all files
mkdir -p ~/cloudwatch-lab
cd ~/cloudwatch-lab
wget https://your-repo/quick-start.sh
wget https://your-repo/cloudwatch-config.json
wget https://your-repo/manage-agent.sh
... (etc)

# Make scripts executable
chmod +x *.sh

# Set up
sudo bash quick-start.sh cloudwatch-config.json
```

Or clone from Git repository:
```bash
git clone https://your-repo/cloudwatch-agent-lab.git
cd cloudwatch-agent-lab
sudo bash quick-start.sh
```

---

## 🆘 Getting Help

**Quick Troubleshooting**:
```bash
# Full health check
sudo bash verify-agent.sh

# Check logs
sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Using management utility
sudo bash manage-agent.sh health
```

**Read Documentation**:
- Stuck at Step 1? → Check `README.md` → Installation Methods
- Agent not running? → Check `COMMAND-REFERENCE.md` → Common Issues
- Need a command? → Check `COMMAND-REFERENCE.md`

**Still stuck?**
1. Check all logs in `/opt/aws/amazon-cloudwatch-agent/logs/`
2. Verify IAM role: `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/`
3. Check configuration JSON is valid: `jq . /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`
4. Review `README.md` Troubleshooting section

---

## 📈 Next Steps After Setup

1. **Create CloudWatch Alarms**
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name high-cpu \
     --alarm-description "Alert when CPU > 80%" \
     --metric-name CPU_IDLE \
     --namespace CustomApplication \
     --statistic Average \
     --period 300 \
     --threshold 20 \
     --comparison-operator LessThanThreshold
   ```

2. **Create Dashboard**
   - Go to CloudWatch Console → Dashboards
   - Add widgets for your metrics

3. **Set Log Retention**
   ```bash
   aws logs put-retention-policy \
     --log-group-name "/aws/ec2/system-logs" \
     --retention-in-days 7
   ```

4. **Create Log Filters**
   - Search for errors automatically
   - Create metrics from log patterns

5. **Scale to Production**
   - Use `deploy-bulk.sh` for multiple instances
   - Or use CloudFormation for repeatable deployments

---

## 📞 Support Resources

- **AWS Documentation**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html
- **Configuration Reference**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html
- **IAM Roles**: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
- **CloudWatch Pricing**: https://aws.amazon.com/cloudwatch/pricing/

---

**Last Updated**: 2024-01-15  
**Version**: 1.0  
**Status**: Ready for Production

---

## Quick Navigation

- 🚀 **Getting Started**: `QUICK-START.md`
- 📚 **Full Reference**: `README.md`
- ⌨️ **Commands**: `COMMAND-REFERENCE.md`
- 📍 **You are here**: `FILE-INDEX.md`
