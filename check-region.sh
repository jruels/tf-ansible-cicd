#!/bin/bash

# Region validation script for Terraform deployment
# Usage: ./check-region.sh [REGION] [AWS_PROFILE]

REGION=${1:-us-west-2}
PROFILE=${2:-default}

echo "🔍 Checking region: $REGION with profile: $PROFILE"

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! AWS_PROFILE=$PROFILE aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured or invalid for profile: $PROFILE"
    exit 1
fi

echo "✅ AWS credentials valid"

# Check availability zones
echo "🌍 Checking availability zones in $REGION..."
AZS=$(AWS_PROFILE=$PROFILE aws ec2 describe-availability-zones \
    --region $REGION \
    --query 'AvailabilityZones[?State==`available`].ZoneName' \
    --output text 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$AZS" ]; then
    echo "❌ Failed to retrieve availability zones for region: $REGION"
    exit 1
fi

AZ_COUNT=$(echo $AZS | wc -w)
echo "✅ Found $AZ_COUNT availability zones: $AZS"

if [ $AZ_COUNT -lt 2 ]; then
    echo "❌ Error: At least 2 availability zones required. Found only $AZ_COUNT."
    echo "💡 Consider using regions like us-west-2, us-east-1, eu-west-1"
    exit 1
fi

# Test Terraform validation
echo "🏗️  Testing Terraform configuration..."
if [ -f main.tf ]; then
    export AWS_PROFILE=$PROFILE
    export TF_VAR_aws_region=$REGION
    
    if terraform validate &> /dev/null; then
        echo "✅ Terraform configuration valid"
    else
        echo "❌ Terraform validation failed"
        terraform validate
        exit 1
    fi
else
    echo "⚠️  main.tf not found in current directory"
fi

# Test Ansible inventory
echo "📋 Testing Ansible inventory..."
if [ -f aws_ec2.yml ]; then
    # Temporarily update region in inventory
    sed -i.bak "s/us-west-[0-9]/$(echo $REGION | sed 's/us-west-/us-west-/')/" aws_ec2.yml
    
    if AWS_PROFILE=$PROFILE ansible-inventory -i aws_ec2.yml --list &> /dev/null; then
        echo "✅ Ansible inventory configuration valid"
    else
        echo "❌ Ansible inventory test failed"
        # Restore backup
        mv aws_ec2.yml.bak aws_ec2.yml
        exit 1
    fi
    
    # Restore backup
    mv aws_ec2.yml.bak aws_ec2.yml
else
    echo "⚠️  aws_ec2.yml not found in current directory"
fi

echo ""
echo "🎉 All checks passed! Region $REGION is ready for deployment."
echo ""
echo "📋 Next steps:"
echo "   1. Update variables.tf: aws_region = \"$REGION\""
echo "   2. Update aws_ec2.yml: regions: - $REGION"
echo "   3. Update .github/workflows/deploy.yml: AWS_REGION: $REGION"
echo "   4. Run: AWS_PROFILE=$PROFILE terraform plan"