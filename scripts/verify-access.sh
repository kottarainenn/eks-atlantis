#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform/1-infra"

ADMIN_ARN=$(terraform output -raw eks_admin_role_arn)
RO_ARN=$(terraform output -raw eks_read_only_role_arn)
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw region)

echo "Configuring admin context..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" --role-arn "$ADMIN_ARN" --alias admin

echo "Configuring read-only context..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" --role-arn "$RO_ARN" --alias ro

echo ""
echo "--- admin role: who am I ---"
kubectl --context admin auth whoami

echo ""
echo "--- admin role: can do anything? (expect yes) ---"
kubectl --context admin auth can-i '*' '*'

echo ""
echo "--- read-only role: can list pods? (expect works/yes) ---"
kubectl --context ro get pods -A

echo ""
echo "--- read-only role: can create deployments? (expect no) ---"
kubectl --context ro auth can-i create deployments -A || true

echo ""
echo "--- read-only role: can read secrets? (expect no) ---"
kubectl --context ro auth can-i get secrets -A || true

echo ""
echo "Verification complete."