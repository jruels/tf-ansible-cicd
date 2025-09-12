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

### Required GitHub Secrets

Add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

```
AWS_ACCESS_KEY_ID       # Your AWS access key
AWS_SECRET_ACCESS_KEY   # Your AWS secret key
SSH_PRIVATE_KEY         # Private key content for EC2 access (corresponding to aws_key_name in variables.tf)
```

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

### Common Issues
1. **SSH Key Issues**: Ensure SSH_PRIVATE_KEY secret matches the AWS key pair
2. **Terraform State**: Pipeline manages state automatically, but manual intervention may be needed for conflicts
3. **VPC Module Issues**: 
   - Ensure AWS provider version compatibility (>= 4.8.0)
   - Check availability zone availability in your region
   - Verify NAT Gateway costs if running in production
4. **Ansible Connection**: Verify security groups allow SSH access from GitHub Actions runners
5. **Application Not Accessible**: Check security groups allow HTTP (port 80) access
6. **Resource Limits**: Ensure your AWS account has sufficient limits for VPC, EIPs, and NAT Gateways

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