#!/usr/bin/env bash
set -e


KUBERNETES_PUBLIC_ADDRESS=$1
TARGET_KUBECONFIG_FILE=$2

kubectl config set-cluster kubelini \
    --certificate-authority=/opt/kubelini/ca/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${TARGET_KUBECONFIG_FILE}

  kubectl config set-credentials system:node:${HOSTNAME} \
    --client-certificate=/opt/kubelini/pki/${HOSTNAME}.pem \
    --client-key=/opt/kubelini/pki/${HOSTNAME}-key.pem \
    --embed-certs=true \
    --kubeconfig=${TARGET_KUBECONFIG_FILE}

  kubectl config set-context default \
    --cluster=kubelini \
    --user=system:node:${HOSTNAME} \
    --kubeconfig=${TARGET_KUBECONFIG_FILE}

  kubectl config use-context default --kubeconfig=${TARGET_KUBECONFIG_FILE}