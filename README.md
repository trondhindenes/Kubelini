# Kubelini aka "Kubernetes the hard way the easy way"

### TLDR
If you want to just get going, head over to:
[How to Run](../blob/master/HOWTO.md)

### Work in progress! 
This repo is not finished in any way

### Background
As an excerise for learning the ins and outs of Kubernetes, I decided to create an Ansible-based deployment of Kelsey Hightower's "Kubernetes the hard way" (https://github.com/kelseyhightower/kubernetes-the-hard-way).

Kubelini does not match "Kubernetes the hard way" 100%, there are slight differences in networking and some of the PKI stuff (see below). However, most of the components are configured as identical as possible to the original.

### What gets deployed
Kubelini deploys Kubernetes 1.8 with Docker 1.13 and Weavenet 2.0.5
### Prerequisites
- Kubelini uses Amazon S3 to distribute certain files (certificates and dynamicly generated config files). Replacing the S3 part with cifs or a similar backend should be fairly easy if s3 is a big no-no for you.
- Kubelini expects a set of already running nodes, and has only been tested with Ubuntu 16.04.
- It is expected that networking is alredy configured: full access between the hosts in the cluster, and ssh access from the Ansible control node to all hosts. Kubelini does _not_ require setting up custom routes, as it uses an overlay network for pod communication.
- You need Ansible. Kubelini was tested with Ansible 2.3.2, but any version above 2.1-ish should work.
- Target nodes need to satisfy the standard Ansible prereqs - which is essentially python and ssh
- You ned an inventory containing 1 or more nodes in a group called "kubernetes_master". These hosts will get etcd/apiserver and other "master" workloads installed.
- You also need a host group called "kubernetes_worker", which should contain 1 or more hosts where actual pods will get scheduled.

### Differences from "Kubernetes the hard way"
1. Certificates: Both Kubernetes and etcd relies on PKI, so there's a lot of certs flying aronud. In "Kubernetes the hard way", a single certificate containing all cluster node ip addresses is used with Kubernetes. Kubelini on the other hand, generates a uniqe cert per node. This allows for scaling out the cluster later, without having to re-issue certificates for every node.
2. Self-signed kubelet certs: "Kubernetes the hard way" uses a new feature in kubelets where a kubelet can auto-generate its own certificate. These auto-generated certificates have some naming issues, so Kubelini uses the per-node certificates described above. This is implemented by first starting the kubelet in "registration mode", and then replacing the certs before restarting. I haven't been able to find a combination of kubelet params that allow this done in any other way (but I'm not giving up on it just yet).
3. Networking: "Kubernetes the hard way" uses kubenet, while Kubelini uses weavenet. The primary reason for this is that by using an overlay we don't have to configure routes on each host or in the network's router. Weavenet takes care of all that. Implementing other cni-based plugins instead shouldn't be too hard.
4. Ip-based communication between apiserver and kubelets: Kubelini explicitly sets the `--kubelet-preferred-address` flag to InternalIP, making sure that apiserver doesn't try and resolve the hostname of nodes when communicating with them. This should increase the robustness of commands like `kubectl log` and `kubectl exec`.
5. Doesn't assume GCE. You can run Kubelini anywhere. The only opinionated piece is the s3 bucket used for exchanging files.

### Things you need to do after running site.yml
For now, we don't automatically set up networking or DNS. That means that after the playbook has run for the first time, the following steps are required:
Log into the first node in the "kubernetes_master" group and perform the following:
```
cd /opt/kubelini/deployments
kubectl apply -f weavenet-config.yml
(wait until the weavenet pods come online)
kubectl -n kube-system get pods
kubectl apply -f dns-deployment.yml
```

Both of the above templates (weavenet and kube-dns) are templated by Ansible to fit the networking settings configured for several of the Kubernetes components. It is therefore important that you use these, and not the "default" vendor deployments for kube-dns and weavenet.

At this point you should have a fully functioning Kubernetes cluster. You can test stuff for example by running (on the same master node as above):   
`kubectl run netutils --image=trondhindenes/netutils -t -i`   
And test that you're able to resolve addresses on the internet by using   
`dig www.google.com`


### Ansible implementation
Kubelini attempts to not use anything "special" in terms of Ansible functionality. The roles included should be very easy to integrate into an existing Ansible setup, and there's no special "bootstrap script". Simply run "ansible-playbook site.yml" as you're used to. The `ansible.cfg` file just points to the local role dir and is really not needed if you don't want it - just make sure your global ansible config somehow is able to "resolve" the roles in this repo. Same goes for the inventory file (`hosts`).

It's worth noting that the inventory group names _are_ referenced a few places inside roles (to figure out the first cluster node ip, etc). If you want to use other group names, then you should do a search+replace in all roles.

All variables can be controlled using group_vars/all.yml. Also, be sure to create / fill inn the following variables in the file `secrets/secrets.yml`:   
- `aws_access_key_id`
- `aws_secret_access_key`

### TODO
- Implement better change tracking: Some of the tasks performed (such as kubelet registration) are not properly idempodent, and will currently execute everytime the playbook is run. 
- Smoother kubernetes api interaction: For now we just fire stuff at kubernetes using kubectl. A "native" Kubernetes module for Ansible is being developed, so watch this space!
- Implement encryption of secrets
