#!/usr/bin/env bash
# Build Docker image and deploy to ECS
# Usage: ./scripts/deploy/build-and-deploy.sh <backend|frontend> <stg|prod>

set -euo pipefail

SERVICE="${1:?Usage: $0 <backend|frontend> <stg|prod>}"
ENV="${2:?Usage: $0 <backend|frontend> <stg|prod>}"

# Load project config
PROJECT_NAME="${PROJECT_NAME:?Set PROJECT_NAME environment variable}"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID environment variable}"

ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-${SERVICE}"
ECS_CLUSTER="${PROJECT_NAME}-${ENV}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"

echo "=== Deploy ${SERVICE} to ${ENV} ==="
echo "ECR: ${ECR_REPO}:${IMAGE_TAG}"
echo "ECS: ${ECS_CLUSTER} / ${SERVICE}"

# 1. ECR login
echo "--- ECR Login ---"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# 2. Build (AMD64 for Fargate)
echo "--- Build ---"
docker build \
  --platform linux/amd64 \
  -t "${ECR_REPO}:${IMAGE_TAG}" \
  -t "${ECR_REPO}:latest" \
  -f "apps/${SERVICE}/Dockerfile" \
  "apps/${SERVICE}"

# 3. Push
echo "--- Push ---"
docker push "${ECR_REPO}:${IMAGE_TAG}"
docker push "${ECR_REPO}:latest"

# 4. Update ECS service
echo "--- Deploy to ECS ---"
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --region "$AWS_REGION"

echo "=== Deploy complete: ${SERVICE} (${ENV}) ==="
echo "Monitor: aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${SERVICE} --query 'services[0].deployments'"
