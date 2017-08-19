KUBERNETES_PUBLIC_ADDRESS=$1
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/opt/kubelini/ca/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=/opt/kubelini/bootstrap_token/kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy \
  --client-certificate=/opt/kubelini/ca/kube-proxy.pem \
  --client-key=/opt/kubelini/ca/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=/opt/kubelini/bootstrap_token/kube-proxy.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kube-proxy \
  --kubeconfig=/opt/kubelini/bootstrap_token/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=/opt/kubelini/bootstrap_token/kube-proxy.kubeconfig