#!/bin/bash

# Test script for Ansible dynamic inventory
# Usage: ./test-inventory.sh [AWS_PROFILE]

PROFILE=${1:-student6}

echo "🧪 Testing Ansible dynamic inventory with profile: $PROFILE"

# Set AWS profile
export AWS_PROFILE=$PROFILE

# Test AWS connectivity
echo "🔐 Testing AWS connectivity..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS credentials not working for profile: $PROFILE"
    exit 1
fi

echo "✅ AWS credentials working"

# Test dynamic inventory
echo "📋 Testing dynamic inventory..."
echo ""
echo "=== INVENTORY LIST ==="
ansible-inventory -i aws_ec2.yml --list --yaml

echo ""
echo "=== INVENTORY GRAPH ==="
ansible-inventory -i aws_ec2.yml --graph

echo ""
echo "=== CHECKING FOR EXPECTED GROUPS ==="
if ansible-inventory -i aws_ec2.yml --list | grep -q "tag_role_k8s_master"; then
    echo "✅ Found tag_role_k8s_master group"
else
    echo "❌ tag_role_k8s_master group not found"
fi

if ansible-inventory -i aws_ec2.yml --list | grep -q "tag_role_k8s_member"; then
    echo "✅ Found tag_role_k8s_member group"  
else
    echo "❌ tag_role_k8s_member group not found"
fi

echo ""
echo "🔍 Available EC2 instances in region:"
aws ec2 describe-instances \
    --region us-west-2 \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`role`].Value|[0],Tags[?Key==`Name`].Value|[0],PublicIpAddress]' \
    --output table