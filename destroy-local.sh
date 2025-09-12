#!/bin/bash

# Local infrastructure destruction script
# Usage: ./destroy-local.sh [AWS_PROFILE]

PROFILE=${1:-student6}

echo "💥 Terraform Infrastructure Destruction Script"
echo "=============================================="
echo "🔧 AWS Profile: $PROFILE"
echo "🌍 Region: us-west-2"
echo ""

# Confirmation prompt
read -p "⚠️  Are you sure you want to DESTROY ALL infrastructure? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 0
fi

# Set AWS profile
export AWS_PROFILE=$PROFILE

# Check AWS connectivity
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS credentials not working for profile: $PROFILE"
    exit 1
fi

echo "✅ AWS credentials verified"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
if ! terraform init; then
    echo "❌ Terraform initialization failed"
    exit 1
fi

# Show current state
echo "📋 Checking current infrastructure..."
if terraform show -json 2>/dev/null | jq -e '.values.root_module.resources | length > 0' > /dev/null 2>&1; then
    echo "✅ Infrastructure found, proceeding with destruction"
    
    echo ""
    echo "🗂️  Current resources:"
    terraform show -json | jq -r '.values.root_module.resources[]? | "   • \(.type): \(.values.tags.Name // .address)"' 2>/dev/null || echo "   • Resource details unavailable"
    echo ""
else
    echo "ℹ️  No infrastructure found to destroy"
    exit 0
fi

# Final confirmation
echo "⚠️  FINAL WARNING: This will destroy ALL resources listed above!"
read -p "Type 'DESTROY' to continue: " final_confirm

if [ "$final_confirm" != "DESTROY" ]; then
    echo "❌ Final confirmation failed. Destruction cancelled."
    exit 0
fi

# Plan destroy
echo "📋 Planning destruction..."
if ! terraform plan -destroy -out=destroy.tfplan; then
    echo "❌ Terraform plan failed"
    exit 1
fi

# Apply destroy
echo "💥 Destroying infrastructure..."
echo "⏰ This may take 5-10 minutes..."
if terraform apply -auto-approve destroy.tfplan; then
    echo "✅ Infrastructure successfully destroyed"
    
    # Clean up files
    echo "🧹 Cleaning up local files..."
    rm -f destroy.tfplan
    echo "✅ Cleanup completed"
    
    echo ""
    echo "💰 All AWS resources have been destroyed and costs stopped"
    echo "🚀 To redeploy: run the GitHub Actions workflow or use terraform apply"
else
    echo "❌ Destruction failed"
    echo "⚠️  Some resources may still exist"
    echo "🔧 Check AWS console for manual cleanup"
    exit 1
fi