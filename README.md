# Terraform + Ansible + GitHub Actions CI/CD Demo

This repository demonstrates a complete CI/CD pipeline that uses:
- **Terraform** to provision AWS infrastructure
- **Ansible** to configure the provisioned instances
- **GitHub Actions** to orchestrate the deployment and build Docker applications

## Architecture

The pipeline creates:
- **Custom VPC** with public and private subnets across multiple AZs
- **Internet Gateway** and **NAT Gateways** for network connectivity
- **AWS EC2 instances** (1 master + 2 workers) in public subnets
- **Security groups** with appropriate rules for k8s cluster
- **Automated Docker installation** and configuration
- **Sample web application** deployment

## Setup Instructions

### Prerequisites

1. **AWS Account** with programmatic access
2. **SSH Key Pair** for EC2 access
3. **GitHub Repository** with Actions enabled

### Step-by-Step GitHub Actions Pipeline Setup

#### Step 1: Create AWS EC2 Key Pair

1. Log into the AWS Console
2. Navigate to EC2 > Network & Security > Key Pairs
3. Click "Create key pair"
4. Name it (e.g., `my-k8s-key`) and choose `.pem` format
5. Download and save the private key file securely
6. Note the key pair name for Step 3

#### Step 2: Configure AWS Credentials

1. Create an IAM user with programmatic access:
   - Go to IAM > Users > Add User
   - Enable "Programmatic access"
   - Attach policies: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`
   - Save the Access Key ID and Secret Access Key

#### Step 3: Set GitHub Repository Secrets

1. Go to your GitHub repository
2. Navigate to `Settings > Secrets and variables > Actions`
3. Add these repository secrets:

```
AWS_ACCESS_KEY_ID       # Your AWS access key from Step 2
AWS_SECRET_ACCESS_KEY   # Your AWS secret key from Step 2  
SSH_PRIVATE_KEY         # Contents of the .pem file from Step 1 (entire file content)
```

**Important**: For `SSH_PRIVATE_KEY`, copy the entire content of your `.pem` file, including the `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines.

#### Step 4: Configure Project Variables

Edit `variables.tf` to match your AWS setup:
```hcl
variable "aws_key_name" {
  description = "AWS key pair name"
  default     = "my-k8s-key"  # Change this to your key pair name from Step 1
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"   # Change to your preferred region
}
```

**Important**: The infrastructure now automatically detects available zones in any region, but your region must have at least 2 availability zones. Recommended regions:
- `us-west-2` (4 AZs) - Default
- `us-east-1` (6 AZs) 
- `eu-west-1` (3 AZs)
- `ap-southeast-1` (3 AZs)

#### Step 5: Validate Your Region (Optional but Recommended)

Use the included validation script to test your region:

```bash
# Test with your AWS profile and preferred region
./check-region.sh us-west-2 student6
```

This script will:
- ✅ Verify AWS credentials work
- ✅ Check that the region has at least 2 availability zones  
- ✅ Validate Terraform configuration
- ✅ Test Ansible inventory connectivity
- ✅ Provide specific guidance if issues are found

### Configuration Files

1. **Update variables.tf** with your AWS configuration:
   - `aws_key_name`: Name of your EC2 key pair in AWS
   - `aws_region`: Your preferred AWS region
   - `aws_master_count`: Number of master nodes (default: 1)
   - `aws_worker_count`: Number of worker nodes (default: 2)
   - `aws_instance_size`: EC2 instance type (default: t3.small)

2. **VPC Configuration**: The infrastructure now automatically creates:
   - Custom VPC with CIDR `10.0.0.0/16`
   - Public subnets: `10.0.1.0/24` and `10.0.2.0/24`
   - Private subnets: `10.0.101.0/24` and `10.0.102.0/24`
   - NAT Gateways for private subnet internet access
   - Internet Gateway for public subnet access

3. **SSH Key Setup**: Ensure your SSH key pair is:
   - Created in AWS EC2 Key Pairs with the name matching `aws_key_name`
   - Private key content added to `SSH_PRIVATE_KEY` GitHub secret

## VPC Module Configuration

The infrastructure uses the official `terraform-aws-modules/vpc/aws` module to create a complete VPC setup:

### Network Architecture
- **VPC CIDR**: `10.0.0.0/16`
- **Availability Zones**: Uses first two AZs in the specified region
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (for EC2 instances)
- **Private Subnets**: `10.0.101.0/24`, `10.0.102.0/24` (for future use)
- **Internet Gateway**: Provides internet access to public subnets
- **NAT Gateways**: Enable internet access for private subnets (one per AZ)

### Module Features
- **DNS Support**: Enables DNS hostnames and resolution
- **Network ACLs**: Uses default VPC network ACLs
- **Route Tables**: Automatically configured for public/private routing
- **Tags**: All resources tagged with environment and name information

### Benefits Over Default VPC
- **Isolation**: Dedicated network environment
- **Customization**: Full control over CIDR blocks and subnets
- **High Availability**: Resources distributed across multiple AZs
- **Scalability**: Easy to add more subnets or modify network configuration

## Running the Pipeline

### Step 6: Trigger the Initial Deployment

1. **Push to trigger pipeline**:
   ```bash
   git add .
   git commit -m "Initial pipeline setup"
   git push origin main
   ```

2. **Monitor the deployment**:
   - Go to your GitHub repository
   - Click on the "Actions" tab
   - Watch the "Deploy Infrastructure and Application" workflow

### Step 7: What to Expect During Initial Run

The pipeline will execute these jobs in sequence:

#### 🔍 **check-infrastructure** (1-2 minutes)
- Initializes Terraform
- Checks if AWS infrastructure already exists
- **Expected outcome**: Since it's the first run, will report "infrastructure_exists=false"

#### 🏗️ **deploy-infrastructure** (5-8 minutes)
- Creates complete AWS VPC infrastructure
- Provisions EC2 instances (1 master + 2 workers)
- **Expected outcome**: 
  - VPC with public/private subnets created
  - Security groups configured
  - EC2 instances launched and running
  - Outputs master and worker IP addresses

#### ⚙️ **configure-infrastructure** (3-5 minutes)
- Installs Python and Ansible
- Connects to EC2 instances via SSH
- Installs Docker on all instances
- **Expected outcome**: Docker installed and running on all nodes

#### 🚀 **build-and-deploy-app** (2-3 minutes)
- Builds Docker image with sample web application
- Deploys to master node on port 80
- **Expected outcome**: Application accessible at http://MASTER_IP

**Total initial deployment time**: ~15-20 minutes

### Step 8: Access Your Application

After successful deployment:

1. **Find your application URL** in the GitHub Actions logs:
   - Look for: "Access your application at: http://[IP_ADDRESS]"
   - Or check the `build-and-deploy-app` job output

2. **Open the application**:
   - Navigate to `http://[MASTER_IP]` in your browser
   - You should see: "🚀 Deployment Successful!" page

3. **SSH access** (if needed):
   ```bash
   ssh -i /path/to/your-key.pem ubuntu@[MASTER_IP]
   ```

## Updating Your Application (Subsequent Runs)

### Step 9: Deploy Application Updates

For subsequent deployments (after initial infrastructure is created):

1. **Modify your application**:
   - Update `index.html` for content changes
   - Update `Dockerfile` for container changes

2. **Commit and push**:
   ```bash
   git add .
   git commit -m "Update application"
   git push origin main
   ```

3. **What happens during updates**:
   - ✅ **check-infrastructure**: Detects existing infrastructure (~1 minute)
   - ⏭️ **deploy-infrastructure**: **SKIPPED** (infrastructure exists)
   - ✅ **configure-infrastructure**: Updates configuration if needed (~2 minutes)
   - ✅ **build-and-deploy-app**: Rebuilds and deploys app (~2 minutes)

**Total update deployment time**: ~5-7 minutes

### Step 10: Pipeline Behavior Summary

| Scenario | check-infrastructure | deploy-infrastructure | configure-infrastructure | build-and-deploy-app |
|----------|---------------------|---------------------|------------------------|-------------------|
| **First Run** | ✅ Run | ✅ Run | ✅ Run | ✅ Run |
| **App Update** | ✅ Run | ⏭️ Skip | ✅ Run | ✅ Run |
| **Infrastructure Destroyed** | ✅ Run | ✅ Run | ✅ Run | ✅ Run |

## Error Handling & Reliability Features

### **🛡️ Automatic Error Prevention**

The infrastructure includes several built-in safeguards to prevent common deployment failures:

#### **Dynamic Availability Zone Detection**
- **Problem Solved**: Hard-coded AZ configurations fail in regions without those specific zones
- **Solution**: Automatically detects and uses available AZs in any AWS region
- **Benefit**: Deploy to any region without configuration changes

#### **Region Validation**
- **Built-in Checks**: Validates region format and AZ availability
- **Requirements**: Ensures at least 2 availability zones exist
- **Fallback**: Provides clear error messages with recommended regions

#### **Resource Validation**
- **Instance Limits**: Validates master (1-3) and worker (1-10) counts
- **Network Configuration**: Automatically creates subnets based on available AZs
- **Key Pair Validation**: Ensures SSH key exists in the specified region

#### **Enhanced Debugging**
Added debug outputs to help troubleshoot issues:
- `available_availability_zones`: Shows all AZs detected in the region
- `selected_availability_zones`: Shows AZs chosen for deployment
- `vpc_public_subnets`: Lists created public subnet CIDRs
- `vpc_private_subnets`: Lists created private subnet CIDRs

### **🔧 Region Validation Tool**

Use the included `check-region.sh` script before deployment:

```bash
# Make executable (first time only)
chmod +x check-region.sh

# Validate region and credentials
./check-region.sh us-west-2 student6

# Test different regions
./check-region.sh us-east-1 student6
./check-region.sh eu-west-1 student6
```

**The script validates**:
- ✅ AWS credentials and profile access
- ✅ Region has sufficient availability zones (≥2)
- ✅ Terraform configuration syntax
- ✅ Ansible inventory connectivity
- ✅ Provides specific fix recommendations

> **💡 Tip**: Commit this script to your repository so team members can use it for validation and troubleshooting.

## How It Works

### First Run (Infrastructure Deployment)
1. **Check Infrastructure**: Determines if infrastructure already exists
2. **Deploy Infrastructure**: If not exists, runs Terraform to create AWS resources
3. **Configure Infrastructure**: Runs Ansible playbook to install Docker and dependencies
4. **Deploy Application**: Builds and deploys the sample web application

### Subsequent Runs (Application Updates)
1. **Check Infrastructure**: Detects existing infrastructure
2. **Skip Infrastructure**: Skips Terraform deployment
3. **Deploy Application**: Only rebuilds and redeploys the application

## Pipeline Jobs

### `check-infrastructure`
- Initializes Terraform
- Checks if infrastructure resources exist
- Outputs infrastructure status and IPs

### `deploy-infrastructure` 
- Only runs if infrastructure doesn't exist
- Creates complete VPC infrastructure using AWS VPC module
- Executes `terraform plan` and `terraform apply`
- Outputs instance IP addresses

### `configure-infrastructure`
- Runs after infrastructure deployment or if infrastructure exists
- Installs Ansible and dependencies
- Executes Docker installation playbook

### `build-and-deploy-app`
- Builds Docker image with sample web application
- Deploys application to the master node
- Application accessible on port 80

### `cleanup-on-failure`
- Runs only if deployment fails
- Destroys infrastructure to prevent orphaned resources

## Customization

### Adding Your Application
1. Replace `Dockerfile` with your application's Docker configuration
2. Replace `index.html` with your application files
3. Modify the build-and-deploy-app job as needed

### Modifying Infrastructure
1. **VPC Configuration**: Modify the VPC module parameters in `main.tf`:
   - Change CIDR blocks for VPC and subnets
   - Adjust availability zones
   - Enable/disable NAT Gateway or VPN Gateway
2. **Instance Configuration**: Update `variables.tf` for instance types and counts
3. **Ansible Playbooks**: Adjust playbooks in the repository
4. **Workflow Updates**: Update the workflow if additional configuration is needed

## Monitoring

- Check GitHub Actions tab for pipeline status
- SSH into instances for debugging: `ssh -i /path/to/key ubuntu@<instance-ip>`
- View application at: `http://<master-instance-ip>`

## Troubleshooting

### Common Pipeline Issues

#### 🔑 **SSH/Authentication Problems**

**Problem**: Pipeline fails with SSH connection errors
```
Permission denied (publickey)
```

**Solutions**:
1. **Verify SSH_PRIVATE_KEY secret**:
   - Ensure it contains the complete .pem file content
   - Include `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines
   - No extra spaces or characters

2. **Check AWS key pair name**:
   - Verify `aws_key_name` in `variables.tf` matches your AWS key pair exactly
   - Key pair must exist in the same region as deployment

#### 🏗️ **Infrastructure Deployment Failures**

**Problem**: `deploy-infrastructure` job fails with AZ errors
```
Error: creating EC2 Subnet: operation error EC2: CreateSubnet, https response error StatusCode: 400
```

**Solutions**:
1. **Use the region validation script**:
   ```bash
   ./check-region.sh us-west-2 student6
   ```
   This will automatically detect and fix AZ availability issues.

2. **Check IAM permissions**:
   - Ensure IAM user has `AmazonEC2FullAccess` and `AmazonVPCFullAccess`
   - Verify AWS credentials are correct in GitHub secrets

3. **Region compatibility**: 
   - The infrastructure now auto-detects available AZs
   - Ensure your region has at least 2 availability zones
   - Try recommended regions: `us-west-2`, `us-east-1`, `eu-west-1`

**Problem**: Terraform state conflicts
```
Error: state lock
```

**Solutions**:
1. **Wait and retry**: Another pipeline run might be in progress
2. **Manual state unlock** (if needed):
   ```bash
   terraform force-unlock [LOCK_ID]
   ```

#### ⚙️ **Ansible Configuration Issues**

**Problem**: `configure-infrastructure` fails to connect
```
UNREACHABLE! => {"msg": "Failed to connect to the host"}
```

**Solutions**:
1. **Wait for EC2 initialization**: Add more wait time after instance creation
2. **Check security groups**: Ensure SSH (port 22) is allowed from 0.0.0.0/0
3. **Verify instance state**: Instances must be in "running" state

#### 🚀 **Application Deployment Issues**

**Problem**: Application not accessible after deployment
```
Connection refused or timeout
```

**Solutions**:
1. **Check security group**: Ensure HTTP (port 80) is allowed from 0.0.0.0/0
2. **Verify Docker container**: SSH to instance and check `docker ps`
3. **Check application logs**:
   ```bash
   ssh ubuntu@[MASTER_IP]
   docker logs demo-app
   ```

#### 💰 **Cost-Related Issues**

**Problem**: Deployment fails due to resource limits
```
Error: creating NAT Gateway: LimitExceeded
```

**Solutions**:
1. **Check AWS limits**: Verify VPC, EIP, and NAT Gateway limits
2. **Reduce worker count**: Lower `aws_worker_count` in `variables.tf`
3. **Disable NAT Gateways** (for development):
   ```hcl
   enable_nat_gateway = false
   ```

### Pipeline-Specific Troubleshooting

#### 🔄 **Pipeline Stuck or Won't Skip Infrastructure**

**Problem**: Pipeline always runs infrastructure deployment even when resources exist

**Cause**: Terraform state not properly detected

**Solution**: Check if terraform state exists:
1. Go to Actions logs
2. Check `check-infrastructure` job output
3. Look for `terraform show -json` results

#### 🧹 **Failed Deployment Cleanup**

**Problem**: Infrastructure left running after failed deployment

**Solution**: The pipeline includes automatic cleanup, but you can manually destroy:
```bash
terraform init
terraform destroy -auto-approve
```

#### 📋 **Debugging Pipeline Steps**

1. **Enable verbose logging**: Add `-v` or `-vv` flags to Ansible commands
2. **Check GitHub Actions logs**: Each job provides detailed output
3. **SSH to instances** for manual debugging:
   ```bash
   ssh -i /path/to/key.pem ubuntu@[INSTANCE_IP]
   ```

### Manual Recovery Steps

If the pipeline fails completely:

1. **Check AWS Console**: Verify which resources were created
2. **Destroy partial infrastructure**:
   ```bash
   terraform destroy -auto-approve
   ```
3. **Clear GitHub Actions cache** (if needed):
   - Go to repository Settings > Actions > Caches
   - Delete relevant caches
4. **Re-run the pipeline**: Push a new commit to trigger deployment

### **Local Testing & Debugging**

Before pushing to GitHub, test locally to catch issues early:

#### **Test Terraform**
```bash
# Validate configuration
AWS_PROFILE=student6 terraform validate

# Check what will be created  
AWS_PROFILE=student6 terraform plan

# Test region compatibility
./check-region.sh us-west-2 student6
```

#### **Test Ansible**
```bash
# Validate playbook syntax
AWS_PROFILE=student6 ansible-playbook --syntax-check -i aws_ec2.yml docker.yml

# Test inventory (after infrastructure exists)
AWS_PROFILE=student6 ansible-inventory -i aws_ec2.yml --list
```

#### **Debug Infrastructure Issues**
```bash
# Check what AZs are available in your region
AWS_PROFILE=student6 aws ec2 describe-availability-zones --region us-west-2

# Verify your key pair exists
AWS_PROFILE=student6 aws ec2 describe-key-pairs --region us-west-2

# Check your AWS account limits
AWS_PROFILE=student6 aws ec2 describe-account-attributes --region us-west-2
```

### Getting Help

1. **Use validation tools first**: Run `./check-region.sh` to catch common issues
2. **Check logs**: Review complete job logs in GitHub Actions
3. **AWS Console**: Verify resource states and quotas  
4. **Test locally**: Use `AWS_PROFILE=student6` commands above
5. **Debug outputs**: Check Terraform outputs for AZ and subnet information

### Manual Cleanup
If needed, manually destroy infrastructure:
```bash
terraform init
terraform destroy -auto-approve
```

## Security Notes

- **Security Groups**: Configured for demo purposes (0.0.0.0/0 access)
- **Production Security**: Restrict access to specific IP ranges and implement least privilege
- **VPC Security**: Custom VPC provides network isolation from other AWS resources
- **SSH Access**: Consider using AWS Systems Manager Session Manager instead of direct SSH
- **Secrets Management**: Store sensitive data in AWS Secrets Manager or GitHub Secrets
- **Network ACLs**: Consider implementing custom Network ACLs for additional security layers

## Cost Considerations

- **NAT Gateways**: Each NAT Gateway costs ~$45/month plus data transfer charges
- **Elastic IPs**: Free when associated with running instances, small hourly charge when unassociated
- **Instance Hours**: EC2 instances incur standard hourly charges based on instance type
- **Data Transfer**: Outbound data transfer charges apply for internet traffic
- **Cost Optimization**: For development, consider disabling NAT Gateways if private subnets aren't used

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the pipeline
5. Submit a pull request