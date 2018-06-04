#!/usr/bin/env bash
set -e

KUBERNETES_PUBLIC_ADDRESS=$1
CLUSTER_ID=$2
kubectl config set-cluster ${CLUSTER_ID} \
  --certificate-authority=/opt/kubelini/ca/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig

kubectl config set-credentials ${CLUSTER_ID} \
  --client-certificate=/opt/kubelini/ca/admin.pem \
  --client-key=/opt/kubelini/ca/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig


kubectl config set-context ${CLUSTER_ID} \
  --cluster=${CLUSTER_ID} \
  --user=${CLUSTER_ID} \
  --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig

kubectl config use-context ${CLUSTER_ID} \
    --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig