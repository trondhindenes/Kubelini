#!/usr/bin/env bash
set -e

KUBERNETES_PUBLIC_ADDRESS=$1
kubectl config set-cluster kubelini \
  --certificate-authority=/opt/kubelini/ca/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig

kubectl config set-credentials kubelini \
  --client-certificate=/opt/kubelini/ca/admin.pem \
  --client-key=/opt/kubelini/ca/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig


kubectl config set-context kubelini \
  --cluster=kubelini \
  --user=kubelini \
  --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig

kubectl config use-context kubelini --kubeconfig=/opt/kubelini/admin_kubeconfig/admin.kubeconfig