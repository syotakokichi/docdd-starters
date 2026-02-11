#!/usr/bin/env bash
# Terraform wrapper script
# Usage: ./scripts/deploy/terraform.sh <environment> <command> [options]
# Example: ./scripts/deploy/terraform.sh stg plan

set -euo pipefail

ENV="${1:?Usage: $0 <stg|prod> <init|plan|apply|destroy|output>}"
COMMAND="${2:?Usage: $0 <stg|prod> <init|plan|apply|destroy|output>}"
shift 2

TF_DIR="terraform/environments/${ENV}"

if [ ! -d "$TF_DIR" ]; then
  echo "Error: Environment directory not found: $TF_DIR"
  exit 1
fi

echo "=== Terraform ${COMMAND} (${ENV}) ==="
cd "$TF_DIR"

case "$COMMAND" in
  init)
    terraform init "$@"
    ;;
  plan)
    terraform plan "$@"
    ;;
  apply)
    terraform apply "$@"
    ;;
  destroy)
    echo "WARNING: Destroying ${ENV} environment!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
      terraform destroy "$@"
    else
      echo "Cancelled."
      exit 0
    fi
    ;;
  output)
    terraform output "$@"
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo "Available: init, plan, apply, destroy, output"
    exit 1
    ;;
esac
