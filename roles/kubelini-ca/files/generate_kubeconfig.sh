BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat > /opt/kubelini/bootstrap_token/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

KUBERNETES_PUBLIC_ADDRESS=$1
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/opt/kubelini/ca/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=/opt/kubelini/bootstrap_token/bootstrap.kubeconfig

kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=/opt/kubelini/bootstrap_token/bootstrap.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kubelet-bootstrap \
  --kubeconfig=/opt/kubelini/bootstrap_token/bootstrap.kubeconfig

kubectl config use-context default --kubeconfig=/opt/kubelini/bootstrap_token/bootstrap.kubeconfig