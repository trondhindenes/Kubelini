systemctl daemon-reload
service etcd stop || true
service kube-apiserver stop || true
service kube-controller-manager stop || true
service kube-scheduler stop || true
service kubelet stop || true
service kube-proxy stop || true
docker rm -f $(docker ps -a -q) || true
docker rmi -f $(docker images -q) || true
service docker stop || true
rm /etc/systemd/system/kube-controller-manager.service || true
rm /etc/systemd/system/kube-scheduler.service || true
rm /etc/systemd/system/kube-apiserver.service || true
rm /etc/systemd/system/etcd.service || true
rm /etc/systemd/system/kubelet.service || true
rm /etc/systemd/system/kube-proxy.service || true
rm /etc/systemd/system/docker.service || true
systemctl daemon-reload
rm /opt/kubelini -rf
rm /etc/etcd -rf
rm /var/lib/kubernetes -rf || true
rm /var/lib/etcd -rf || true
rm /var/lib/kube-proxy -rf || true
rm /var/lib/kubelet -rf || true
rm /var/run/kubernetes -rf || true
rm /opt/cni -rf || true
rm /usr/bin/kubectl || true
rm /usr/bin/kube-apiserver || true
rm /usr/bin/kube-controller-manager || true
rm /usr/bin/kube-scheduler || true
rm /usr/bin/kubelet || true
rm /usr/bin/kube-proxy || true

