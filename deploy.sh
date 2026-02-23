#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy.sh [tag]
TAG="${1:-latest}"

REGION="${REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-120569640932}"
ECR_REPO="${ECR_REPO:-myproject-dev-app}"
ECR_URI="${ECR_URI:-${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}}"

CLUSTER="${CLUSTER:-myproject-dev-cluster}"
SERVICE="${SERVICE:-myproject-dev-service}"

NEW_IMAGE="${ECR_URI}:${TAG}"

# Pre-req check
command -v aws >/dev/null || { echo "❌ aws cli not found"; exit 1; }
command -v jq  >/dev/null || { echo "❌ jq not found. Install: brew install jq"; exit 1; }

echo "📦 Deploying image: ${NEW_IMAGE}"
echo "📍 Cluster: ${CLUSTER}"
echo "🧩 Service: ${SERVICE}"
echo

# Get current task definition ARN
CURRENT_TD=$(aws ecs describe-services \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --query 'services[0].taskDefinition' \
  --output text)

echo "Current task def: $CURRENT_TD"

# Pull full task definition JSON
aws ecs describe-task-definition \
  --region "$REGION" \
  --task-definition "$CURRENT_TD" \
  --query 'taskDefinition' > /tmp/td.json

# Update container image + remove read-only fields
NEW_TD=$(jq --arg IMAGE "$NEW_IMAGE" '
  .containerDefinitions[0].image = $IMAGE
  | del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
' /tmp/td.json)

# Register new revision
NEW_TD_ARN=$(aws ecs register-task-definition \
  --region "$REGION" \
  --cli-input-json "$NEW_TD" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

echo "New task def: $NEW_TD_ARN"

# Update service to new revision
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$NEW_TD_ARN" \
  --force-new-deployment >/dev/null

echo "⏳ Waiting for service to become stable..."
aws ecs wait services-stable \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

echo "✅ Deployed successfully!"
echo "🔎 Verifying image on task definition..."
aws ecs describe-task-definition \
  --region "$REGION" \
  --task-definition "$NEW_TD_ARN" \
  --query 'taskDefinition.containerDefinitions[0].image' \
  --output text