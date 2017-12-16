$HostNameLower = ($Env:ComputerName).ToLower()
 
 & C:\kube\kubelet.exe `
--allow-privileged=true `
--anonymous-auth=false `
--client-ca-file=C:\kube\certs\ca.pem `
--cluster-dns=10.32.0.10 `
--cluster-domain=cluster.local `
--container-runtime=docker `
--network-plugin=cni `
--serialize-image-pulls=false `
--register-node=true `
--tls-cert-file=C:\kube\certs\worker1.pem `
--tls-private-key-file=C:\kube\certs\worker1-key.pem `
--v=2 `
--kubeconfig=C:\Kube\config\$($HostNameLower).kubeconfig `
--image-gc-high-threshold=85 `
--maximum-dead-containers-per-container=3 `
--hostname-override=worker1 `
--cni-bin-dir="c:\cni" `
--cni-conf-dir "c:\cni\config"