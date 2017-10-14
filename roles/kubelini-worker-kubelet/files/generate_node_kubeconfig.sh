#!/usr/bin/env bash
set -e


KUBERNETES_PUBLIC_ADDRESS=$1

kubectl config set-cluster kubelini \
    --certificate-authority=/opt/kubelini/pki_downloads/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=/opt/kubelini/${HOSTNAME}.kubeconfig

  kubectl config set-credentials system:node:${HOSTNAME} \
    --client-certificate=/opt/kubelini/pki_downloads/${HOSTNAME}.pem \
    --client-key=/opt/kubelini/pki_downloads/${HOSTNAME}-key.pem \
    --embed-certs=true \
    --kubeconfig=/opt/kubelini/${HOSTNAME}.kubeconfig

  kubectl config set-context default \
    --cluster=kubelini \
    --user=system:node:${HOSTNAME} \
    --kubeconfig=/opt/kubelini/${HOSTNAME}.kubeconfig

  kubectl config use-context default --kubeconfig=/opt/kubelini/${HOSTNAME}.kubeconfig