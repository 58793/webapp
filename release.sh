#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-v$(date +%Y%m%d-%H%M%S)}"

REGION="${REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-120569640932}"
ECR_REPO="${ECR_REPO:-myproject-dev-app}"
ECR_URI="${ECR_URI:-${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}}"

CLUSTER="${CLUSTER:-myproject-dev-cluster}"
SERVICE="${SERVICE:-myproject-dev-service}"

echo "🔐 ECR login..."
aws ecr get-login-password --region "$REGION" \
| docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "🐳 Building local image: myapp:${TAG}"
docker build -t "myapp:${TAG}" .

echo "🏷️ Tagging for ECR: ${ECR_URI}:${TAG}"
docker tag "myapp:${TAG}" "${ECR_URI}:${TAG}"

echo "📤 Pushing to ECR..."
docker push "${ECR_URI}:${TAG}"

echo "🚀 Deploying to ECS using deploy.sh..."
./deploy.sh "${TAG}"

echo "✅ Done. Image deployed: ${ECR_URI}:${TAG}"
