# Kubelini aka "Kubernetes the hard way the easy way"

### Work in progress! 
This repo is not finished in any way

### Background
As an excerise for learning the ins and outs of Kubernetes, I decided to create an Ansible-based deployment of Kelsey Hightower's "Kubernetes the hard way" (https://github.com/kelseyhightower/kubernetes-the-hard-way).

Kubelini does not match "Kubernetes the hard way" 100%, there are slight differences in networking and some of the PKI stuff (see below). However, most of the components are configured as identical as possible to the original.

### Prerequisites
- Kubelini uses Amazon S3 to distribute certain files (certificates and dynamicly generated config files). Replacing the S3 part with cifs or a similar backend should be fairly easy if s3 is a big no-no for you.
- Kubelini expects a set of already running nodes, and has only been tested with Ubuntu 16.04.
- It is expected that networking is alredy configured: full access between the hosts in the cluster, and ssh access from the Ansible control node to all hosts.
- You need Ansible. Kubelini was tested with Ansible 2.3.2, but any version above 2.1-ish should work.
- Target nodes need to satisfy the standard Ansible prereqs - which is essentially python and ssh

### Differences from "Kubernetes the hard way"
1. Certificates: Both Kubernetes and etcd relies on PKI, so there's a lot of certs flying aronud. In "Kubernetes the hard way", a single certificate containing all cluster node ip addresses is used with Kubernetes. Kubelini on the other hand, generates a uniqe cert per node. This allows for scaling out the cluster later, without having to re-issue certificates for every node.
2. Self-signed kubelet certs: "Kubernetes the hard way" uses a new feature in kubelets where a kubelet can auto-generate its own certificate. These auto-generated certificates have some naming issues, so Kubelini uses the per-nodde certificates described above. This is implemented by first starting the kubelet in "registration mode", and then replacing the certs before restarting. I haven't been able to find a combination of kubelet params that allow this done in any other way
3. Networking: "Kubernetes the hard way" uses kubenet, while Kubelini uses weavenet. Implementing other cni-based plugins instead shouldn't be too hard.
4. Ip-based communication between apiserver and kubelets: Kubelini explicitly sets the `--kubelet-preferred-address` flag to InternalIP, making sure that apiserver doesn't try and resolve the hostname of nodes when communicating with them.

### Ansible implementation
Kubelini attempts to not use anything "spesial" in terms of Ansible functionality. The roles included should be very easy to integrate into an existing Ansible setup, and there's no special "bootstrap script". Simply run "ansible-playbook site.yml" as you're used to.

It's worth noting that the inventory group names _are_ referenced a few places inside roles (to figure out the first cluster node ip, etc). If you want to use other group names, then you should do a search+replace in all roles.