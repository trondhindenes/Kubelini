

Prep windows binaries (doesn't have to be on the actual kubernetes node)


1. Download https://storage.googleapis.com/kubernetes-release-dashpole/release/v1.9.0-beta.2/kubernetes-node-windows-amd64.tar.gz

2. Clone https://github.com/Microsoft/SDN



References:
https://www.youtube.com/watch?v=U-riSIm7AbM&t=560s


# DOit:
- Install Chocolatey
```
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

- Ansible prep script:
```
Invoke-Webrequest -UsebasicParsing -Uri "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1" -Outfile C:\prep\ansibleprep.ps1
```

- Install git
```
choco install git.install --params="'/NoShellIntegration'" -y
choco install visualstudiocode -y
Restart-Computer -Force
```

- Download k8s:
```
start-bitstransfer https://storage.googleapis.com/kubernetes-release-dashpole/release/v1.9.0-beta.2/kubernetes-node-windows-amd64.tar.gz -Destination "C:\prep\kubernetes-node-windows-amd64.tar.gz"
```

- Install 7zip4powershell and unzip kubernetes binaries
```
Install-PackageProvider -Name NuGet -Force
Install-Module 7Zip4PowerShell -force
mkdir "C:\prep\kubernetes-node-windows-amd64" | out-null
Expand-7Zip "C:\prep\kubernetes-node-windows-amd64.tar.gz" "C:\prep\kubernetes-node-windows-amd64"
Expand-7Zip "C:\prep\kubernetes-node-windows-amd64\kubernetes-node-windows-amd64.tar" "C:\prep\kubernetes-node-windows-amd64"
```


- Download and install go
```
Start-Bitstransfer "https://redirector.gvt1.com/edgedl/go/go1.8.5.windows-amd64.msi" -Destination "C:\prep\go1.8.5.windows-amd64.msi"
msiexec /i "C:\prep\go1.8.5.windows-amd64.msi"
```

- Clone Flannel and build
```
mkdir "C:\k8s_things" | out-null
mkdir "C:\k8s_things\flannel" | out-null
mkdir "C:\GOPATH" | out-null
mkdir "C:\GOPATH\src" | out-null
[System.Environment]::SetEnvironmentVariable('GOPATH', "C:\GOPATH\", [System.EnvironmentVariableTarget]::Machine)
Restart-Computer -Force

mkdir "C:\GOPATH\src\github.com" | out-null
mkdir "C:\GOPATH\src\github.com\rakelkar" | out-null
cd "C:\GOPATH\src\github.com\rakelkar"
git clone https://github.com/rakelkar/flannel.git
cd "flannel"
git checkout jroggeman/windows_impl
go get -v ./...
go build
Copy-item flannel.exe -Destination "C:\k8s_things\flannel" -force



go get
go build -o dist/flanneld

cd "C:\prep\go"
git clone https://github.com/containernetworking/plugins.git containernetworking_plugins
cd containernetworking_plugins
```

- Install docker on the node
```
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name Docker -ProviderName DockerMsftProvider -force
Restart-Computer -Force
```

- Flanneld expects the node name lower-cased as such:
```
[System.Environment]::SetEnvironmentVariable('NODE_NAME', ($Env:Computername).ToLower(), [System.EnvironmentVariableTarget]::Machine)
Restart-Computer -Force
```

- Set up CNI/Flannel stuff
```
mkdir C:\cni | out-null
mkdir C:\cni\config | out-null
mkdir C:\etc | out-null
mkdir C:\etc\kube-flannel | out-null
copy-item C:\prep\Kubernetes_on_Windows\flannel_config\CNI.CONF C:\cni\config\
copy-item C:\prep\Kubernetes_on_Windows\flannel_config\NET-CONF.json C:\etc\kube-flannel\
Start-BitsTransfer https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/windows/cni/wincni.exe -Destination "C:\prep\wincni.exe"
Copy-item "C:\prep\wincni.exe" "C:\cni"
```

- Set up kubernetes
```
mkdir C:\kube | out-null
mkdir C:\kube\certs | out-null
$Items = "kubectl.exe","kubelet.exe","kube-proxy.exe"
foreach ($Item in $Items)
{
    Copy-item (join-path "C:\prep\kubernetes-node-windows-amd64\kubernetes\node\bin" $Item) -Destination "C:\kube"
}
```

- Start the thing:
```
cd "C:\k8s_things\flannel"
.\flannel.exe --kubeconfig-file="C:\Kube\kubeconfig" --iface=“NODE_ETHO_IP" --ip-masq=1 --kube-subnet-mgr=1
```