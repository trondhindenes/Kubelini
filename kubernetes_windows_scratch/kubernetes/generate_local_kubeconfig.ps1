$KUBERNETES_PUBLIC_ADDRESS=$args[0]
$HostNameLower = ($Env:ComputerName).ToLower()

& C:\kube\kubectl config set-cluster kubelini `
    --certificate-authority=C:\Kube\certs\ca.pem `
    --embed-certs=true `
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 `
    --kubeconfig=C:\Kube\config\$($HostNameLower).kubeconfig

& C:\kube\kubectl config set-credentials system:node:$($HostNameLower) `
    --client-certificate=C:\Kube\certs\$($HostNameLower).pem `
    --client-key=C:\Kube\certs\$($HostNameLower)-key.pem `
    --embed-certs=true `
    --kubeconfig=C:\Kube\config\$($HostNameLower).kubeconfig

& C:\kube\kubectl config set-context default `
    --cluster=kubelini `
    --user=system:node:$($HostNameLower) `
    --kubeconfig=C:\Kube\config\$($HostNameLower).kubeconfig

& C:\kube\kubectl config use-context default --kubeconfig=C:\Kube\config\$($HostNameLower).kubeconfig